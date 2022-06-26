import React, {useState, useEffect} from 'react';

import './App.css';

import getWeb3 from './getWeb3';

import { Vendor_ABI, Vendor_contractAddress } from './Vendor_Contract';
import { ABI, contractAddress } from './ABI_Contract';
import Web3 from 'web3';




const App = () =>{
  //Inicializa valores al iniciar la aplicacion
  const [netId, setNetworkId ] = useState('');
  const [netType, setNetType] = useState('');
  const [contractOwner, setContractOwner ] = useState('');
  const [activeAccount, setActiveAccount] = useState(''); 
  const [accountBalance, setAccountBalance] = useState('');
  const [amountBuy, setAmountBuy] = useState(100);
  const [amountSell, setAmountSell] = useState(100);
  const [tokenBalance, setTokenBalance] = useState('');
  const [contractBalance, setContractBalance] = useState('');
  const [contractTokenBal, setContractTokenBal] = useState('');
  const [owner, setOwner ] = useState( false );


  const init = async () => {
    const web3 = await getWeb3();
    const netId = await web3.eth.net.getId();
    setNetworkId(netId);
    const netType = await web3.eth.net.getNetworkType();
    setNetType(netType);
    const accounts = await web3.eth.getAccounts();
    //const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    setActiveAccount(accounts[0]);
    const acBalance = await web3.eth.getBalance( accounts[0] );
    setAccountBalance( acBalance / 1e18 );
  }

  const contractInfo = async () => {

    const web3 = await getWeb3();

    let contractBal = await web3.eth.getBalance( Vendor_contractAddress );
    contractBal = contractBal / 1e18;
    setContractBalance( contractBal );

    //Vendor Contract
    const tc = new web3.eth.Contract( Vendor_ABI, Vendor_contractAddress);

    const contractOwner = await tc.methods.contractOwner().call();
    console.log('contract Owner >', contractOwner);
    setContractOwner( contractOwner ); 

    const accounts = await web3.eth.getAccounts();
    //const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    const activeAccount = accounts[0];
    console.log('activeAccount >',activeAccount);

    if ( activeAccount === contractOwner ) {
      setOwner( true );
    } else {
      setOwner( false );
    }

    //Token Contract
    const tc2 = new web3.eth.Contract( ABI, contractAddress )

    const tokenBalance = await tc2.methods.balanceOf(activeAccount ).call(); 
    setTokenBalance( tokenBalance ); 

    const contractTokenBal = await tc2.methods.balanceOf(Vendor_contractAddress )
    .call();
    setContractTokenBal( contractTokenBal ); 

  }

  const buyToken = async (buyQty) => {
    console.log('The buyToken function:',buyQty);

    const web3 = new Web3(window.ethereum);

    if(web3 == null){
      console.log('Error: Web object creation');
      return;
    }

    let check = buyQty % 100;
    //Doble ==//!= compara el valor sin importar sin son de tipos distintos, ej '5'==5 => true
    //Triple ===//!== compara igualdad estricta con el valor mismos tipos de dato, ej '5'==5 => false
    if(check !== 0){
      console.log('Error: Token quantity must be in x100',buyQty);
      return;
    }

    //Convert into Ether value and into Wei
    let howMuch = buyQty / 100; //Value in ether
    let valueInWei = await web3.utils.toWei(howMuch.toString(),'ether');
    console.log('Value in Wei:',valueInWei);

    const accounts = await web3.eth.getAccounts();
    //const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });

    const tc = new web3.eth.Contract(Vendor_ABI,Vendor_contractAddress);

    await tc.methods.buyToken().send({from:accounts[0],to:Vendor_contractAddress,value:valueInWei},
      (err,res) => {
        if(err){
          console.log('Buy token failed:',err);
          return;
        }else{
          console.log('Buy token sucess:',res);
        }
      }).on('receipt',(receipt) => {
          console.log('Buy token Receipt > ',receipt);
        });
  }

  const sellToken = async (tokenQty) => {
    const web3 = new Web3(window.ethereum);

    const accounts = await web3.eth.getAccounts();
    //const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });

    const tc = new web3.eth.Contract(ABI, contractAddress);

    //Es necesario aprovar al vendor para acceder a la cuenta por el valor deseado a vender.
    //Aprovar al vendor en nombre del vendedor
    await tc.methods.approve(Vendor_contractAddress,tokenQty).send({
      from: accounts[0],
      to: Vendor_contractAddress
    }, (err,res) =>{
      if(err){
          console.log('Approval of allowances failed:',err);
          return;
        } else{
          console.log('Approval sucess:',res);
        }
    });

    //Pagar dinero al vendedor, transferir del vendor al vendedor
    const tc2 = new web3.eth.Contract(Vendor_ABI,Vendor_contractAddress);

    //Send para cuando se desea enviar la transaccion, involucra escribir en la blockchain
    //Call para cuando se desea recuperar la transaccion (retrieve)
    await tc2.methods.sellToken(tokenQty).send({
      from: accounts[0],
      to: Vendor_contractAddress
    }, (err,res) => {
      if(err){
        console.log('Sell token failed:',err);
        return;
      } else{
        console.log('Sell token sucess:',res);
      }
    });
  }

  const withdraw = async () => {

    try {

      const confirm = window.confirm("Withdraw all contract Ether?");
      //Doble ==//!= compara el valor sin importar sin son de tipos distintos, ej '5'==5 => true
      //Triple ===//!== compara igualdad estricta con el valor mismos tipos de dato, ej '5'==5 => false
      if (confirm === false ) return;

      const web3 = new Web3(window.ethereum);
      const contractBal = await web3.eth.getBalance(Vendor_contractAddress);

      if (contractBal <= 0 ) {
        window.alert('Contract balance has no Ether');
        return;
      }
      const tc = new web3.eth.Contract(Vendor_ABI, Vendor_contractAddress);
      const contractOwner = await tc.methods.contractOwner().call();

      await tc.methods.withdrawal().send({ 
        from:contractOwner,
        to: Vendor_contractAddress 
      }, (err,res) => {
        if (err) {
          console.log('Withdrawl failed ', err);  
          return
        } else {
          console.log('Withdrawal success ', res);
        } 
    });
  } catch (error) {
    console.log('error > ', error)
  }
}

useEffect(() => {
  init();
  contractInfo(); 
}, []);


return (

  <div className='App'>

    <h1>Welcome to Alpha Token</h1>
     <h2>BlockChain Type: <span className='orangeText'>  {netType} </span> &nbsp;  Net id: <span className='orangeText'> { netId } </span> </h2>
     <p>Contract address: <span className='orangeText'>  {Vendor_contractAddress} </span> </p>
     <p>Owner of Contract: <span className='orangeText'>  {contractOwner} </span>   </p>
     <p>Contract Balance: <span className='orangeText'> {contractBalance} </span>Ether</p>
     <p>Contract AXC Token: <span className='orangeText'> {contractTokenBal}  </span></p>
     <p>______________________________________________________________________________</p>
     
     <p>Your Account: <span className='clearText' > {activeAccount} </span></p>
     <p>Value Balance: <span className='clearText'>{accountBalance}</span> Ether</p>
     <p>AXC Token Balance: <span className='clearText'> {tokenBalance} </span></p>
     <p>Price: 1 Ether = 100 PKT Tokens</p>
     <button className='btn2' onClick={() => {window.location.reload()} }>Refresh</button>
     
     <input className='inputNum' type='number' name="amountBuy" min='100' id='qtyBuy' step='100'
         value={amountBuy} onChange={ (e) => setAmountBuy(e.target.value)}> 
     </input>
     
     <button className='btn2' onClick={() => buyToken(amountBuy) }>Buy Token</button>
     <input className='inputNum' type='number' name="amountSell" min='100' id='qtySell' step='100' max='5000'
         value={amountSell} onChange={ (e) => setAmountSell(e.target.value)}> 
     </input>
     <button className='btn2' onClick={() => sellToken( amountSell )   }>Sell Token</button>
     
     <button className='btn2' disabled={!owner } onClick={() => withdraw()  } >Withdrawal</button>
      
    </div>
  );

}

export default App;

/*
LINKS
https://stackoverflow.com/questions/64557638/how-to-polyfill-node-core-modules-in-webpack-5
*/