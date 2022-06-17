import { expect } from "chai";
import { Contract, Signer } from "ethers";
import { parseEther } from "ethers/lib/utils";
import { ethers } from "hardhat";

describe("Token contract", function () {
  let game;
  let gameContract: Contract;

  let owner: Signer;
  let addr1: Signer;
  let addr2: Signer;
  let addr3: Signer;
  let addr4: Signer;
  let addr5: Signer;
  let addr6: Signer;

  beforeEach(async function () {
    game = await ethers.getContractFactory("GuessGame");
    [owner, addr1, addr2, addr3, addr4, addr5, addr6] =
      await ethers.getSigners();
    gameContract = await game.deploy();
  });

  describe("main flow", function () {
    it("main flow test", async function () {
      //create game with 3 users
      await expect(gameContract.connect(addr1).createGame(101, 3, { value: parseEther("1") })).to.be.revertedWith("incorrect value");
      await expect(gameContract.connect(addr1).createGame(3, 3, { value: parseEther("0") })).to.be.revertedWith("value is not sufficiant");
      await (gameContract.connect(addr1).createGame(3, 3, { value: parseEther("3") }))
      await expect(gameContract.connect(addr1).finishGame(1)).to.be.revertedWith("not time yet to finish")
      await expect(gameContract.connect(addr2).guessNumber(1, 20, { value: parseEther("10") })).to.be.revertedWith("incorrect value");
      await gameContract.connect(addr2).guessNumber(1, 30, { value: parseEther("3") });
      await gameContract.connect(addr3).guessNumber(1, 40, { value: parseEther("3") });
      await expect(gameContract.connect(addr4).guessNumber(1, 20, { value: parseEther("3") })).to.be.revertedWith("Not enough places");
      await ethers.provider.send("evm_increaseTime", [1 * 1 * 10 * 60]);

      await expect(gameContract.connect(addr4).guessNumber(1, 20, { value: parseEther("3") })).to.be.revertedWith("game finished");
      gameContract.connect(addr1).finishGame(1);
      let rnd = await gameContract.variableToTest();

      console.log(rnd);
      let abs1 = Math.abs(rnd - 3);
      let abs2 = Math.abs(rnd - 30);
      let abs3 = Math.abs(rnd - 40);

      if (Math.min(abs1, abs2, abs3) == abs1) {
        expect(await gameContract.connect(addr1).getBalance()).to.equal(parseEther("9"))
      } else if (Math.min(abs1, abs2, abs3) == abs2) {
        expect(await gameContract.connect(addr2).getBalance()).to.equal(parseEther("9"))

      } else {
        expect(await gameContract.connect(addr3).getBalance()).to.equal(parseEther("9"))

      }















    });
  });
});
