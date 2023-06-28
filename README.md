# TreeCave Web3 Backend

This repository contains the smart contract code for the DAO-Cave project which is an Ethereum-based decentralized autonomous organization (DAO) platform. It's built with Solidity, Hardhat, and Ethers.js. It also includes tests written in TypeScript.

## Table of Contents

- [Installation](#installation)
- [Running Tests](#running-tests)
- [Deploying to a Local Hardhat Network](#deploying-to-a-local-hardhat-network)
- [Contributing](#contributing)
- [License](#license)

## Installation

1. Clone the repository and navigate to the directory

2. Install the dependencies

    ```
    npm install
    ```

3. Create a `.env` file in the root directory and set the values as per your requirements.

    ```
    ETHERSCAN_API_KEY=yourInfuraKey
    PRIVATE_KEY=yourPrivateKey
    ```

## Running Tests

You can run tests using the following command:

```
npm run test
```


## Deploying to a Local Hardhat Network

To deploy your contract to a local Hardhat network, run:

```
npm run deploy
```


## Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a pull request

Please make sure to update the tests as appropriate.

## License

[MIT](https://choosealicense.com/licenses/mit/)
