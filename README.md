# contract-wallets
Hello! This is a repository of some proof-of-concept implementations of various smart contract wallet ideas. None of these contracts are tested and none of them are meant to be used as-is. These contracts are mainly just examples of the types of interesting economic mechanisms people can inject into smart contract wallets. TL;DRs of the different designs are provided in this README.

## Contributing
If you have ideas for new wallet prototypes, you see a flaw in an existing one, or you'd just like to chat about this stuff, feel free to reach out. I'm most accessible via Twitter (@kelvinfichter).

## Contracts
### ConfirmationWallet
`ConfirmationWallet` is a simple wallet that supports ETH transfers that require a second "confirmation" transaction. Whenever the owner of the wallet wants to send a transaction, they must first submit a transaction that initiates the transfer but doesn't actually send any funds. The owner can then either confirm the transaction and send off the funds or cancel the transaction and return the funds to the contract.

The basic rationale for wanting a wallet like this is that sending crypto is terrifying [citation needed]. People usually resort to sending "test transaction" to make sure they've got the right recipient address, their wallet software is working properly, etc. etc. Cancellations are nice because the recipient address can be reviewed by looking at what was published to Ethereum (no wallet funny business). 

### TimeDelayWallet
`TimeDelayWallet` is almost identical to `ConfirmationWallet` with the addition of a timeout window on each transfer. The sender can cancel transactions at any time, but the recipient is allowed to confirm the transaction once the timeout window has elapsed.

### DeadXWallet
`DeadXWallet` is a fun concept I've played with before. It's basically a fancy dead x's switch with some cryptoeconomics sprinkled on top. Generally the contract just acts like a normal ETH wallet. However, the owner specifies a list of "beneficiaries". At any time, a beneficiary can attempt to "recover" the funds from the contract by staking some bond. This recovery attempt starts a timeout during which the owner can cancel the attempt and take the beneficiary's bond.

You can probably see the point of this. If the owner's keys are actually inaccessible (e.g. the owner is lying in a ditch somewhere), they won't be able to cancel the recovery attempt and the beneficiary will get the funds. However, if reports of the owner's death have been greatly exaggerated (or a beneficiary is just trying to swipe some cash), the owner can cancel the recovery attempt and be paid for their trouble. 

One interesting topic of study here is the bond size necessary for this system to work. It's something I've been researching a lot lately in the context of plasma. Without going into too much detail, the size of the bond necessary depends primarily on the length of the timeout window and the value of funds in the contract. A (relatively small) $100 bond and a timeout window of at least a month makes the system secure even for balances in the millions.
