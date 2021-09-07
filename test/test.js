const { ethers, upgrades } = require('hardhat');
const { expect } = require("chai");

let owner, addr1, addr2;

let accountContract;

beforeEach(async function () {
	[owner, addr1, addr2] = await ethers.getSigners();
	const AccountContract = await ethers.getContractFactory('AccountContract');
	accountContract = await AccountContract.deploy();
})

describe("Test", function () {
	it("Account Contract Test", async function() {
		await expect(accountContract.add(addr1.address))
			.to.emit(accountContract, 'AddAccount')
			.withArgs(addr1.address);

		await expect(accountContract.add(addr2.address))
			.to.emit(accountContract, 'AddAccount')
			.withArgs(addr2.address);

		await expect(accountContract.connect(addr1).remove(addr2.address))
			.to.emit(accountContract, 'RemoveAccount')
			.withArgs(addr2.address);

		const size = await accountContract.size();
		await expect(size).to.equal(1);
	});
});
