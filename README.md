# NFC Wallet
Turn any NFC tag into an abstracted account on @Base and tap to pay at whitelisted stations.

<img width="1567" alt="Screenshot 2024-03-17 at 2 33 18 AM" src="https://github.com/citizenwallet/ethglobal-london-app/assets/74358/3a4487cb-1eba-43df-b13b-46b04bdf7c43">

- Presentation ([PDF](https://drive.google.com/open?id=1PhEhAsJCYNqnLX4w0aG8ymtfUgd8WHib&usp=drive_fs))
- Video ([Google Drive](https://drive.google.com/open?id=1PgxUp80CbuqSbbKbGT0N1qlAdbtd8SNz&usp=drive_fs))



<img width="1794" alt="Screenshot 2024-03-17 at 2 35 37 AM" src="https://github.com/citizenwallet/ethglobal-london-app/assets/74358/8b6efd3c-db38-4330-8478-a944537559f5">

<img width="1787" alt="Screenshot 2024-03-17 at 2 36 01 AM" src="https://github.com/citizenwallet/ethglobal-london-app/assets/74358/89f19e1c-bf45-4115-b8af-67dd5c52f125">
<img width="800" alt="Screenshot 2024-03-17 at 2 35 12 AM" src="https://github.com/citizenwallet/ethglobal-london-app/assets/74358/84f6a54d-fa0e-4f98-bb5b-ae8f9bcfdcda">
Webapp: https://nfcwallet.vercel.app (Chrome on Android only)



## Description

When you organize an event or manage a community space, it’s great to be able to give participants an NFC card, tag or wristband for access control.

With Account Abstraction, we can now turn those NFC tags into a wallet that can hold any asset. People can now top up their NFC tag and tap to pay at a series of whitelisted stations (terminals that have their own account that is whitelisted to avoid abuse).

It allows you to do simple transactions in stablecoins or any other token that can represent finite resources (e.g. number of drinks, food, etc.).

It can be used at events like Ethglobal to manage payment and finite resources to make sure that these are distributed fairly.

Tokens can represent resources like: 
- Food
- Drinks (e.g. coffee machine)
- Meeting rooms
- Workshop access
- Print credits
- …

Next to the NFC wallet we implemented a native NFC payment terminal/PoS application (using Flutter) that can easily withdraw assets from the NFC wallet.

For security reasons the withdrawal devices need to be whitelisted to be able to withdraw funds from the cards.

## How it's made
Tell us about how you built this project; the nitty-gritty details. What technologies did you use? How are they pieced together? If you used any partner technologies, how did it benefit your project? Did you do anything particularly hacky that's notable and worth mentioning?

## Cards & Tags
**Tech:** Solidity, ERC4337, ERC20, Smart Contract Accounts, NFC Web API, NFC (iOS & Android)
**Purpose:** Provide something physical which has a unique identifier that people can use to hold and pay with assets on chain. Side goal: convert all ETHGlobal wristbands into Smart Accounts.

The core concept here is that based on a serial number, we are able to generate a Smart Contract Address. The serial number is not stored or sent to the chain, it is converted to a hash off-chain and then sent to the Smart Contract.

The serial numbers are obtained by reading the serial number of NFC tags. 

This is a hexadecimal number that we pack and keccack256 hash together with the chain id and smart contract address to generate a bytes32 “cardHash”.

This “cardHash” is used to get, create or withdraw from a card.

This stops people being able to just scan the contract for created accounts and creates the necessity for the original NFC tag to be read. 

For this to work, we use two smart contracts. A Manager contract and a smart account contract. The Manager contract uses CREATE2 to counterfactually generate account addresses. 

Cards are fully-fledged Smart Account Contracts and can always be “detached” from their Card Manager by transferring ownership away.

## Whitelist
**Tech:** Solidity
**Purpose:** Have control over who can withdraw from the Cards. Register known vendors or kiosks that would accept these cards.

Cards have a “withdrawTo” function which can only be called by accounts in a whitelist. This whitelist is stored in the Manager that deploys them. This whitelist is therefore global to all Cards and can be updated by the owner of the Manager contract.

## NFC POS App
**Tech:** Flutter, iOS, Android, NFC, ERC4337, Smart Contract Accounts, Bundler
**Purpose:** Provide an easy way for a vendor to specify products, amounts and collect assets from an NFC tag’s Smart Account.

A simple Flutter app with two screens:
Configuration: create a list of products with names and prices. 
Vendor mode: tap a product to enable NFC tag scanning and collect the amount specified

When the POS App starts, it generates a private key for itself and a Smart Account associated with it. Its Account address can then be whitelisted on the Card Manager.

It is then able to withdraw from Cards without the need for gas. 

Since Cards don’t need to be deployed until a function call is required, they are only deployed the first time the “withdrawTo” function is called on the Card Manager.

Same with the App’s own Smart Account. In true ERC4337 fashion, it is only deployed when the first transaction is made to withdraw from a card.

## NFC Web Reader
**Tech:** NextJS, React, Scaffold ETH 2, Web NFC API
**Purpose:** Provide an easy way for users to view the balance of their NFC tag. Bonus: load the profile photo and name from the ETHGlobal wristband.

Anyone who has an NFC tag can tap it to a device that is compatible with the Web NFC API and has an NFC reader. This works with any recent Android device on Chrome. iOS is not supported. 

If it is an ETHGlobal wristband and contains a link to the user’s profile, display their photo and name.

Users can see the balance of their wristband’s Smart Account on the assets that it supports.

## ERC4337
**Tech:** Bundler, Paymaster

In order to create a smooth experience, gas fees are sponsored using ERC4337.

We use Citizen Wallet’s Community Entrypoint, Bundler and Paymaster to process the user operations. It’s simple, fast and restricted to the ERC20 token we are working with.

## Chain
**Tech:** Base Mainnet and Base Sepolia

We tested our implementation on Base Sepolia and then published to Base Mainnet.

Base is fast, reliable and has become cost effective to use thanks to the recent L2 gas optimizations that have been implemented.

## Noteworthy

We turned all ETHGlobal NFC bracelets into Smart Accounts that can transact USDC on Base. These bracelets can be topped up and pay using the POS App. 

## References:

Card Manager is an adaptation of the Ethereum Foundation’s “Simple Account Factory” (https://github.com/eth-infinitism/account-abstraction/blob/v0.6.0/contracts/samples/SimpleAccountFactory.sol ).

Card is an adaptation of the Ethereum Foundation’s “Simple Account” (https://github.com/eth-infinitism/account-abstraction/blob/v0.6.0/contracts/samples/SimpleAccount.sol ).

Card Manager is deployed along with an implementation of Card (https://basescan.org/address/0x8B493e025A14c83e7A1789b7e2dE7C7b283F38ac#writeContract  ). This allows it to be a factory for cards. 

A Sample Card that was deployed by the Card Manager (https://basescan.org/address/0xb67440cc61Aa4748406fDBE778eECF956a0ea873#tokentxns ). It has received 1 USDC (https://basescan.org/tx/0xd7fdadfc67c54c2f0c9422d039db32aa36b782fb02091f6f8bc5526f15105ee7 ) and paid 1 USDC (https://basescan.org/tx/0xb2549636095808f6c59d55fa7adf959578eda039d8a7f03b5361ac94adc7a4f3 ) to a POS App’s Smart Contract Account.

POS App Smart Contract Account (https://basescan.org/address/0x25Ce37c0198c9f5B814E77Bb4Dc42e68937E95Da#readProxyContract ). 

Keep in mind that the code is stored in 2 separate Git repos
NFC Webapp Read: https://github.com/citizenwallet/ethglobal-london-webapp

POS App + Smart Contracts: https://github.com/citizenwallet/ethglobal-london-app


## Next steps: 
- Integration into citizenwallet as a read only account
- Take ownership of the account fully importing it in your wallet by a claim function
- Multitoken card
- Not only show 1 currency but also finite resources
- In each community finite resources should be distributed across members. Through their NFCwallet users can consume their finite resources. 
- Easy integration with Low code
- Giving low code implementation easy access to a physical transaction solution
