const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = ethers;

describe("MyContract", function () {
  let MyContract;
  let myContract;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    MyContract = await ethers.getContractFactory("MyContract");
    [owner, addr1, addr2] = await ethers.getSigners();
    myContract = await MyContract.deploy();
  });

  // describe("Calc X", function () {
  //   it("Should calculate X correctly for given inputs", async function () {
  //     // Use BigNumber to handle large inputs
  //     // const X1 = 1335901511702n;
  //     // const Y1 = 65823374119855021975121778n;
  //     // const X2 = 1733208409840235993850831n;
  //     // const Y2 = 4683488309595915518201484n;
  //     // const X3 = 38071843842838687363725530n;
  //     // const Y3 = 596631232087n;

  //     const X1 = 353701n;
  //     const Y1 = 11485246n;
  //     const X2 = 103887428n;
  //     const Y2 = 100031748n;
  //     const X3 = 859739278585n;
  //     const Y3 = 636934316214n;

  //   //   1.350114246238861e+31
  //   //   5.35005506851533e+25
  //   //   9.388896892057533e+30

  //     const result = await myContract.calculateArbitrageValues(X1, Y1, X2, Y2, X3, Y3);
  //     console.log(result.toString());

  //   // Add more test cases with different inputs
  //   });
  // });

  // describe("withdraw test", function () {
  //   it("msg.sender", async function () {

  //     console.log(owner);
  //     const result = await myContract.withdraw();
  //     console.log(JSON.stringify(result));

  //   });
  // });

  describe("withdraw test", function () {
    it("msg.sender", async function () {

      const result = await myContract.expect22();
      console.log(JSON.stringify(result));

    });
  });

//   describe("Owner Management", function () {
//     it("Should set the right owner", async function () {
//       expect(await myContract.owner()).to.equal(owner.address);
//     });

//     it("Should not allow transferring ownership to the zero address", async function () {
//       await expect(myContract.transferOwnership(ethers.constants.AddressZero)).to.be.revertedWith("New owner is the zero address");
//     });

//     it("Should allow the owner to transfer ownership", async function () {
//       await myContract.transferOwnership(addr1.address);
//       expect(await myContract.owner()).to.equal(addr1.address);
//     });

//     it("Should not allow non-owner to transfer ownership", async function () {
//       await expect(myContract.connect(addr1).transferOwnership(addr2.address)).to.be.revertedWith("Not the contract owner");
//     });
//   });

//   describe("Math Operations", function () {
//     it("Should calculate the square root correctly", async function () {
//       let result = await myContract.sqrt(16);
//       expect(result).to.equal(4);

//       result = await myContract.sqrt(25);
//       expect(result).to.equal(5);

//       result = await myContract.sqrt(0);
//       expect(result).to.equal(0);

//       result = await myContract.sqrt(2);
//       expect(result).to.equal(1);
//     });
    
//     it("Should calculate X correctly for given inputs", async function () {
//       const X1 = 1335901511702;
//       const Y1 = 65823374119855021975121778;
//       const X2 = 1733208409840235993850831;
//       const Y2 = 4683488309595915518201484;
//       const X3 = 38071843842838687363725530;
//       const Y3 = 596631232087;

//       const result = await myContract.getX(X1, Y1, X2, Y2, X3, Y3);
//       console.log(result.toString());

//       // Expected result should be known or calculated
//       const expectedResult = // put your expected result here
//       expect(result).to.equal(expectedResult);
//     });

//     // Add more test cases with different inputs
//   });

//   describe("Uniswap Interaction Mocks", function () {
//     beforeEach(async function () {
//       // Set expected responses by interacting with mocked contracts
//       await uniswapV1FactoryMock.setExchange("0xA8206C1fda9Ed9C73E787ea1DA2aC75a354DF2E1");
//       await uniswapV2FactoryMock.setPair("0xE72EcE3b2536d413639aa134a2085800a8211083");
//     });

//     it("Should retrieve V1 pair details correctly", async function () {
//       const pairAddress = await uniswapV1FactoryMock.getExchange("0xA8206C1fda9Ed9C73E787ea1DA2aC75a354DF2E1");
//       expect(pairAddress).to.not.equal(ethers.constants.AddressZero);
//     });

//     it("Should retrieve V2 pair details correctly", async function () {
//       const pairAddress = await uniswapV2FactoryMock.getPair("0xA8206C1fda9Ed9C73E787ea1DA2aC75a354DF2E1", "0xE72EcE3b2536d413639aa134a2085800a8211083");
//       expect(pairAddress).to.not.equal(ethers.constants.AddressZero);
//     });
//   });

//   describe("Pool Reservations", function () {
//     it("Should retrieve pool reservation details", async function () {
//       const token0 = "0xA8206C1fda9Ed9C73E787ea1DA2aC75a354DF2E1";
//       const token1 = "0xE72EcE3b2536d413639aa134a2085800a8211083";

//       const result = await myContract.PoolReservations1(token0, token1);
//       const pairs = result[0];
//       const reserves = result[1];
//       const tokens = result[2];

//       expect(pairs.length).to.be.greaterThan(0);
//       expect(reserves.length).to.be.greaterThan(0);
//       expect(tokens.length).to.be.greaterThan(0);
//     });
//   });
});