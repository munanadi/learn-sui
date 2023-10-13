# learn sui

1. Install sui binaries - either testnet, devnet, or mainnet
2. sui start - to get the localnet up and runnig
3. sui client switch --env localnet - to switch to the localnet
4. sui client publish --gas-budget 2000000 - to publish the module
5. Take the module id from the previous step. 
6. sui client call --function mint --module hello_world --package <PACKAGE_ID> --gas-budget 10000
7. Go to https://suiexplorer.com/address/<OBJECT_ID>?network=local to see the objects that you created