// We import Chai to use its asserting functions here.
const { expect } = require("chai"); // Ref: https://sz-piotr-waffle.readthedocs.io/en/latest/matchers.html
// describe is a Mocha function that allows you to organize your tests. It's
// not actually needed, but having your tests organized makes debugging them
// easier. All Mocha functions are available in the global scope.

// describe receives the name of a section of your test suite, and a callback.
// The callback must define the tests of that section. This callback can't be
// an async function.
describe("Sota Token Contract", function () {
  // Mocha has four functions that let you hook into the the test runner's
  // lifecyle. These are: before, beforeEach, after, afterEach.

  // They're very useful to setup the environment for tests, and to clean it
  // up after they run.

  // A common pattern is to declare some variables, and assign them in the
  // before and beforeEach callbacks.

  let SotaToken;
  let hardhatSotaToken;
  let deployer;

  // addr1, addr2: creators
  // addr3: not creator
  let addr1, addr2, addr3, addr4, addrs;
  let creator1, creator2, creator3, customer;

  // Respectively: deployer's address, creator1's address, creator2's address, customer's address.
  let daddr, cr1addr, cr2addr, cr3addr, csaddr;

  // beforeEach will run before each test, re-deploying the contract every
  // time. It receives a callback, which can be async.
  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    SotaTokenV1 = await ethers.getContractFactory("SotaToken");
    [deployer, addr1, addr2, addr3, addr4, ...addrs] =
      await ethers.getSigners();

    // To deploy our contract, we just have to call SotaToken.deploy() and await
    // for it to be deployed(), which happens onces its transaction has been
    // mined.
    hardhatSotaToken = await upgrades.deployProxy(SotaTokenV1, ["sotatoken", "sta"] ,{
      kind: "uups",
    });

    //await hardhatSotaToken.deployed();

    creator1 = hardhatSotaToken.connect(addr1);
    creator2 = hardhatSotaToken.connect(addr2);
    creator3 = hardhatSotaToken.connect(addr3);
    // Normal user: neither admin nor creator.
    customer = hardhatSotaToken.connect(addr4);

    // Set addresses.
    // daddr = deployer.signer.address;
    daddr = deployer.address;
    cr1addr = creator1.signer.address;
    cr2addr = creator2.signer.address;
    cr3addr = creator3.signer.address;
    csaddr = customer.signer.address;
  });

  /**
   * Purposes:
   *
   * - This is a sample test.
   *
   */
  describe("Deployment", function () {
    // it is another Mocha function. This is the one you use to define your
    // tests. It receives the test name, and a callback function.

    // If the callback function is async, Mocha will await it.
    it("Should set the right uri", async function () {
      // Expect receives a value, and wraps it in an Assertion object. These
      // objects have a lot of utility methods to assert values.

      // This test expects the uri set to the right value.
      expect(await hardhatSotaToken.uri(0)).to.equal("");
    });
  });


  describe("Burn Token", function () {
    beforeEach(async function () {
      await hardhatSotaToken.addCreator(cr1addr);
      await hardhatSotaToken.addCreator(cr2addr);
    });

    describe("Single Burn", function () {
      describe("Burn none-free ep", function () {
        beforeEach(async function () {
          await creator1["mint(address,string,bool,uint256,bytes)"](
            daddr,
            "cr1pb1",
            false,
            10,
            0
          ); // id = 1
        });

        it("Should be able for admin to burn token", async function () {
          expect(
            await hardhatSotaToken["balanceOf(address,uint256)"](cr1addr, 1)
          ).to.equal(10);

          await hardhatSotaToken["burn(address,uint256,uint256)"](
            cr1addr,
            1,
            2
          );

          expect(
            await hardhatSotaToken["balanceOf(address,uint256)"](cr1addr, 1)
          ).to.equal(8);
        });

        it("Should not be able to burn token if not admin role", async function () {
          expect(
            await hardhatSotaToken["balanceOf(address,uint256)"](cr1addr, 1)
          ).to.equal(10);
  
          await expect(creator1["burn(address,uint256,uint256)"](cr1addr, 1, 2)).to.be.reverted;
        });

        it("Should be able to burn with half of token is publishing", async function () {
          await creator1.publish(1,5);
          expect(await hardhatSotaToken.isPublishedToken(1)).to.be.true;
  
          // Still can burn half of ep that are private.
          await hardhatSotaToken["burn(address,uint256,uint256)"](cr1addr, 1, 5);
        });  
      });

      

      describe("Burn free ep", function () {
        beforeEach(async function () {
          await creator1["mint(address,string,bool,uint256,bytes)"](
            daddr,
            "cr1fpb1",
            true,
            1,
            0
          ); // id = 1
        });
        it("Should be able to burn free-ep with amount = 1", async function () {
          expect(
            await hardhatSotaToken["balanceOf(address,uint256)"](cr1addr, 1)
          ).to.equal(1);

          await hardhatSotaToken["burn(address,uint256,uint256)"](cr1addr, 1, 1);
          expect(
            await hardhatSotaToken["balanceOf(address,uint256)"](cr1addr, 1)
          ).to.equal(0);
        });

        it("Should be able to burn free-ep with amount = random", async function () {
          expect(
            await hardhatSotaToken["balanceOf(address,uint256)"](cr1addr, 1)
          ).to.equal(1);

          await hardhatSotaToken["burn(address,uint256,uint256)"](cr1addr, 1, 100000);
          expect(
            await hardhatSotaToken["balanceOf(address,uint256)"](cr1addr, 1)
          ).to.equal(0);
        });
      });

    });

    
  });
});
