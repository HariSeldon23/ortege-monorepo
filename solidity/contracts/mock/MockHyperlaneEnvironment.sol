// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./MockMailbox.sol";
import "../middleware/InterchainQueryRouter.sol";

import {TypeCasts} from "../libs/TypeCasts.sol";

contract MockHyperlaneEnvironment {
    uint32 originDomain;
    uint32 destinationDomain;

    mapping(uint32 => MockMailbox) public mailboxes;
    mapping(uint32 => InterchainQueryRouter) public queryRouters;

    constructor(uint32 _originDomain, uint32 _destinationDomain) {
        originDomain = _originDomain;
        destinationDomain = _destinationDomain;

        MockMailbox originMailbox = new MockMailbox(_originDomain);
        MockMailbox destinationMailbox = new MockMailbox(_destinationDomain);

        mailboxes[_originDomain] = originMailbox;
        mailboxes[_destinationDomain] = destinationMailbox;

        InterchainQueryRouter originQueryRouter = new InterchainQueryRouter();
        InterchainQueryRouter destinationQueryRouter = new InterchainQueryRouter();

        originQueryRouter.initialize(
            address(this),
            address(originMailbox),
            address(0)
        );
        destinationQueryRouter.initialize(
            address(this),
            address(destinationMailbox),
            address(0)
        );

        originQueryRouter.enrollRemoteRouter(
            _destinationDomain,
            TypeCasts.addressToBytes32(address(destinationQueryRouter))
        );
        destinationQueryRouter.enrollRemoteRouter(
            _originDomain,
            TypeCasts.addressToBytes32(address(originQueryRouter))
        );

        queryRouters[_originDomain] = originQueryRouter;
        queryRouters[_destinationDomain] = destinationQueryRouter;
    }

    function processNextPendingMessage() public {
        mailboxes[destinationDomain].processNextInboundMessage();
    }

    function processNextPendingMessageFromDestination() public {
        mailboxes[originDomain].processNextInboundMessage();
    }
}