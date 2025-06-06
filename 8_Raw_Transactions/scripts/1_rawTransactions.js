const path = require('path');
const pathToDotEnv = path.join(__dirname, '..', '..', '.env');
require("dotenv").config({ path: pathToDotEnv });


const { ethers } = require("ethers");
console.log(ethers.version);

// Todo: Update this contract address.
const cAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const cName = "Greeting";

const getContract = async (
    signer = deployer
) => {
    // Fetch the ABI from the artifacts.
    const cABI = require("../artifacts/contracts/" +
        cName +
        ".sol/" +
        cName +
        ".json").abi;

    // Create the contract and print the address.
    const c = new ethers.Contract(cAddress, cABI, signer);

    // console.log(cName + " address: ", c.address);

    return c;
};


// Exercise 1: Raw transaction with no parameters: aided encoding.
//////////////////////////////////////////////////////////////////

// In Ethereum everything is a transaction. Invoking a method on a smart 
// contract is no exception, that is a transaction too.

// Now, instead of invoking a smart contract's method like a human, you will
// do it like your client is doing it behind the scenes, that is with a 
// "raw transaction."

// A raw transaction is a transaction to a contract address with a special
// `data` parameter (other parameters are available, but let's focus on data).

// The `data` parameter contains the ABI encoded signature of the method, plus
// any input parameter append along. For instance: 

// - Encoded signature of a method with no input parameters:
//   "0xc48d6d5e"
// - Encoded signature of a method with two input parameters: 
//   "0xcdcd77c000000000000000000000000000000000000000000000000000000000000000450000000000000000000000000000000000000000000000000000000000000001"

// We'll understand the nitty gritty details in the next exercise. For now, 
// we will use this website:

// https://abi.hashex.org/

// to get the encoded signature for the method `reset()` of the
// contract Greeting.
// Hint: No parentheses.

const rawTransactionBasic = async () => {
    
    const [signer, deployer] = await hre.ethers.getSigners();
    console.log("Signer 1: ", signer.address);
    console.log("Signer 2: ", deployer.address);
    console.log();

    console.log("Exercise 1. Raw Transactions with Encoding from Hashex.org.");
    console.log();
    
    const contract = await getContract(deployer);
    // Reset contract state.
    await contract.reset();

    let greeting = await contract.greeting();
    console.log("Current greeting:", greeting);
    
    // Updating greeting.
    await contract.setGreeting("Buongiorno");
    
    greeting = await contract.greeting();
    console.log("Updated greeting:", greeting);
    
    console.log();
    console.log("**Raw transaction**: reset()");
    console.log();

    // Fill in this value with the encoded signature of reset():
    let encodedSignature = "d826f88f"; 
    let calldata = "0x" + encodedSignature;

    // Raw transaction.
    const tx = await signer.sendTransaction({
        to: cAddress,
        data: calldata
    });
    
    await waitForTx(tx);
    
    greeting = await contract.greeting();
    console.log("Greeting after reset:", greeting);
    
};

// rawTransactionBasic();


// Exercise 2: Raw transaction with no parameters: do your own encoding.
///////////////////////////////////////////////////////////////////////

// Now that you got the gist of raw transactions, it's time to understand
// how to do your own encoding.

// To get a function signature, you need to hash the prototype string of
// function with Keccak256. Then extract its first 4 bytes.

// Here is additional explanation with examples.
// https://docs.soliditylang.org/en/v0.8.11/abi-spec.html#examples

// Luckily, we have worked with Keccack256 in the previous exercise sheet.
// It is time to send your first raw transaction.


// Takes a function's signature as input and returns the Keccak256 hash.
const doKeccak256 = (signature) => {
  let hash = hre.ethers.id(signature)
  return String(hash).substring(0, 10)
}

const rawTransactionDIY = async () => {

    const [signer, deployer] = await hre.ethers.getSigners();
    console.log("Signer 1: ", signer.address);
    console.log("Signer 2: ", deployer.address);
    console.log();

    console.log("Exercise 2. Raw Transactions with Own Encoding.");
    console.log();

    const contract = await getContract(deployer);
    // Reset contract state.
    await contract.reset();

    let greeting = await contract.greeting();
    console.log("Current greeting:", greeting);

    // Updating greeting.
    await contract.setGreeting("Buongiorno");

    greeting = await contract.greeting();
    console.log("Updated greeting:", greeting);
    
    console.log();
    console.log("**Raw transaction**: reset()");
    console.log();
    
    // Hash the signature with Keccak256.
    let signature = "reset()";
    
    let calldata = doKeccak256(signature);
    console.log("Hashed signature:", calldata);


    // Your code here!
    // let calldata = ... ;


    const tx = await signer.sendTransaction({
        to: cAddress,
        data: calldata
    });

    await waitForTx(tx);

    greeting = await contract.greeting();
    console.log("Greeting after reset:", greeting);
};

// rawTransactionDIY();


// Exercise 3: Raw transaction with _static_ parameters & do your own encoding.
///////////////////////////////////////////////////////////////////////////////

// Input parameters to a function belongs to roughly two types:

// - dynamic: length defined at run-time (arrays, strings, bytes)
// - static:  length predefined at compilation time (all other types)

// This distinction is important for the encoding because ABI encoding needs
// to fit everything in chunks of fixed length (32 bytes), and user-inputed
// dynamic types might be longer or shorter than that.

// Let's start with the simple case, static types.

// Hint: Use the function zeroPadValue; it takes a Bytes-like
// array (toBeArray will be useful).

// Hint2: You can compare your own encoding with the output from
// https://abi.hashex.org/


// Takes a function's signature as input, hashes with Keccak256,
// and return the first 4 bytes. Optionally, takes a verbose
// parameter to print to console its operations.
const encodeSignature = (signature, verbose) => {
  if (verbose) console.log(`Input signature: ${signature}`)
  let hash = hre.ethers.id(signature)
  if (verbose) console.log(`Keccak256 hash of signature: ${hash}`)
  result = String(hash).substring(0, 10)
  if (verbose) console.log(`Extracting the first four bytes: ${result}`)
  return result
};

const rawTransactionStaticParams = async () => {

    const [signer, deployer] = await hre.ethers.getSigners();
    console.log("Signer 1: ", signer.address);
    console.log("Signer 2: ", deployer.address);
    console.log();

    console.log("Exercise 3. Raw Transactions with Static Types.");
    console.log();

    const contract = await getContract(deployer);
    // Reset contract state.
    await contract.reset();

    let greeting = await contract.greeting();
    console.log("Current greeting:", greeting);

    // Set greeting with raw transaction.

    let signature = "chooseGreeting(uint8)";
    // Hash the signature with Keccak256 and takes 4 bytes.
    let encodedSignature = encodeSignature(signature);

    // Your code here (hint above).

    let calldata = hre.ethers.concat([encodedSignature, hre.ethers.zeroPadValue(hre.ethers.toBeArray(2), 32)])

    console.log();
    console.log("**Raw transaction**: chooseGreeting(uint8)");
    console.log();

    let tx = await signer.sendTransaction({
        to: cAddress,
        data: calldata
    });

    await waitForTx(tx);

    // Check if greeting was updated.
    greeting = await contract.greeting();
    console.log("Updated greeting:", greeting);

    console.log();
    console.log("**Raw transaction**: reset()");
    console.log();
    
    // Reset.
    signature = "reset()";
    calldata = encodeSignature(signature);

    tx = await signer.sendTransaction({
        to: cAddress,
        data: calldata
    });

    await waitForTx(tx);

    greeting = await contract.greeting();
    console.log("Greeting after reset:", greeting);    
};

// rawTransactionStaticParams();

// Exercise 4: Raw transaction with _dynamic_ parameters & do your own encoding.
//////////////////////////////////////////////////////////////////////

// Now let's do it even more complicated. Let's send dynamic parameters along.

// Manually encoding dynamic parameters is rather complex:

// https://docs.soliditylang.org/en/v0.8.11/abi-spec.html#formal-specification-of-the-encoding

// Fortunately, Ethers.JS has a utility function that does the job for you.

// Hint: check the Ethers.JS doc about how to create an `ABI Coder` and
// then use the .encode(...) method.

// Hint2: You can compare your own encoding with the output from
// https://abi.hashex.org/

const rawTransactionDynamicParams = async () => {

    const [signer, deployer] = await hre.ethers.getSigners();
    console.log("Signer 1: ", signer.address);
    console.log("Signer 2: ", deployer.address);
    console.log();

    console.log("Exercise 4. Raw Transactions with Dynamic Types.");
    console.log();

    const contract = await getContract(deployer);
    // Reset contract state.
    await contract.reset();

    let greeting = await contract.greeting();
    console.log("Current greeting:", greeting);

    // Set greeting with raw transaction.

    let signature = "setGreeting(string)";
    // Hash the signature with Keccak256 and takes 4 bytes.
    let encodedSignature = encodeSignature(signature);
    
    // Encode String parameter "Buongiorno", or get inspired here:
    // https://www.berlitz.com/blog/hello-different-languages

   
    // Your code here (hint above).
    let abiCoder = hre.ethers.AbiCoder.defaultAbiCoder()
    let paramsData = abiCoder.encode(["string"], ["Buongiorno"])
    let calldata = hre.ethers.concat([encodedSignature, paramsData])

    console.log();
    console.log("**Raw transaction**: setGreeting(string)");
    console.log();

    let tx = await signer.sendTransaction({
        to: cAddress,
        data: calldata
    });

    await waitForTx(tx);

    // Check if greeting was updated.
    greeting = await contract.greeting();
    console.log("Updated greeting:", greeting);

    console.log();
    console.log("**Raw transaction**: reset()");
    console.log();
    
    // Reset.
    signature = "reset()";
    calldata = encodeSignature(signature);

    tx = await signer.sendTransaction({
        to: cAddress,
        data: calldata
    });

    await waitForTx(tx);

    greeting = await contract.greeting();
    console.log("Greeting after reset:", greeting);    
};

// rawTransactionDynamicParams();


// Helper:

const waitForTx = async (tx, verbose) => {
    console.log();
    console.log("Transaction in mempool...");
    if (verbose) console.log(tx);
    else console.log('Nonce:', tx.nonce, 'Hash:', tx.hash);
    await tx.wait();
    console.log("Transaction mined!");
    console.log();
};
