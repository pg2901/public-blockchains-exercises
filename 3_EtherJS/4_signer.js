// Loading path module for operations with file paths.
const path = require('path');

// Ethers JS: Signers.
//////////////////////

// A Signer wraps all operations that interact with an account. An account
// generally has a private key located somewhere, which can be used to sign a
// variety of types of payloads.

// The private key may be located in memory (using a Wallet) or protected via
// some IPC layer, such as MetaMask which proxies interaction from a website to
// a browser plug-in, which keeps the private key out of the reach of the 
// website and only permits interaction after requesting permission from the
// user and receiving authorization.

// See: https://docs.ethers.org/v6/getting-started/

// Exercise 0. Load dependencies and network provider.
//////////////////////////////////////////////////////

// a. Require the `dotenv` and `ethers` packages.
// Hint: As you did in file 1_wallet and 2_provider.

require('dotenv').config()
const ethers = require('ethers')

// b. Create a Sepolia provider.
const providerKey = process.env.ALCHEMY_KEY;
const sepoliaUrl = `${process.env.ALCHEMY_SEPOLIA_API_URL}${providerKey}`;
const sepoliaProvider = new ethers.JsonRpcProvider(sepoliaUrl);

// Exercise 1. Create a Signer.
///////////////////////////////

// Important! Do not use the private key of an account where actual money
// is held. Use only a test account. 

// Create with the Metamask private key saved in your .env file. No need to 
// connect to provider now.

// Verify that the address matches your Metamask address.

// Hint: a signer is a wallet.
// Hint2: if you get an error here, check that the private key begins with "0x".
const testKey = process.env.METAMASK_1_PRIVATE_KEY
const testAddress = process.env.METAMASK_1_ADDRESS

let sepoliaSigner = new ethers.Wallet(testKey)

// Exercise 2. Sign something.
//////////////////////////////

const sign = async (message = 'Hello world') => {
    console.log(await sepoliaSigner.signMessage(message))
};

// sign();

// Exercise 3. Connect to the blockchain. 
/////////////////////////////////////////

// a. Connect the signer to the Sepolia network.
// Hint: .connect()

// b. Print the next nonce necessary to send a transaction.
// Hint: .getNonce()

const connect = async() => {
  sepoliaSigner = sepoliaSigner.connect(sepoliaProvider)
  console.log(await sepoliaSigner.getNonce())
};

// connect();

// c. Replace the signer created above at exercise 1 with one that takes the 
// Sepolia provider as second parameter. This is necessary even
// if you connected inside the function connect() because there might be
// some issues with the asynchronicity of when the connection is established
// and the remaning of the exercises. If unclear, just check the solution :)

// Replace the signer created above.
sepoliaSigner = new ethers.Wallet(testKey, sepoliaProvider)

// Exercise 4. Send a transaction.
//////////////////////////////////

// The time has come to send a transaction programmatically! 

// a. Send some Ether from one of your accounts to another one using the
// method `sendTransaction()`. Obtain the transaction id and check on Etherscan
// when the transaction get mined.
// Hint: `sendTransaction()` returns an object with info about the transaction.
// Hint2: The `value` field is specified in XX. You could use the utility
// function `parseEther()` to format the number accordingly.

// b. Instead of looking on Etherscan, wait for the transaction to be mined,
// then compare the balance of both addresses before and after.
// Hint: `sendTransaction()` returns an object with a `wait()` method.
// Hint2: `formatEther()` can print a nicer balance.

const account2 = process.env.METAMASK_2_ADDRESS;

const sendTransaction = async () => {
  console.log('Before Giver: ' + ethers.formatEther(await sepoliaProvider.getBalance(testAddress)))
  console.log('Before Receiver: ' + ethers.formatEther(await sepoliaProvider.getBalance(account2)))
  const request = {
    to: account2, 
    value: ethers.parseEther("0.0001")
  }
  const tx = await sepoliaSigner.sendTransaction(request)
  console.log('transaction in mempool')
  await tx.wait()
  console.log('transaction mined')

  console.log('After Giver: ' + ethers.formatEther(await sepoliaProvider.getBalance(testAddress)))
  console.log('After Receiver: ' + ethers.formatEther(await sepoliaProvider.getBalance(account2)))
};

// sendTransaction();

