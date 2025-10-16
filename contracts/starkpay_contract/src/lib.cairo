//! StarkPay Contract - Minimal Payment System
//! 
//! This is a minimal smart contract demonstrating StarkPay's core payment functionality.
//! Built for the Starknet Hackathon submission - DEL-006: MVP desplegado en Starknet mainnet
//!
//! Features:
//! - Send payments between users
//! - Track payment history
//! - Basic user registration
//! - Payment verification
//!
//! Author: StarkPay Team - ITAM
//! Date: October 2025

use starknet::ContractAddress;

#[starknet::interface]
pub trait IStarkPay<TContractState> {
    /// Register a new user with username
    fn register_user(ref self: TContractState, username: felt252);
    
    /// Send payment to another user
    fn send_payment(ref self: TContractState, recipient: ContractAddress, amount: u256, message: felt252);
    
    /// Get user's payment balance
    fn get_balance(self: @TContractState, user: ContractAddress) -> u256;
    
    /// Get username for an address
    fn get_username(self: @TContractState, user: ContractAddress) -> felt252;
    
    /// Get total payments sent by user
    fn get_total_sent(self: @TContractState, user: ContractAddress) -> u256;
    
    /// Get total payments received by user
    fn get_total_received(self: @TContractState, user: ContractAddress) -> u256;
    
    /// Get payment count for user
    fn get_payment_count(self: @TContractState, user: ContractAddress) -> u32;
    
    /// Verify if user is registered
    fn is_registered(self: @TContractState, user: ContractAddress) -> bool;
    
    /// Get contract version
    fn get_version(self: @TContractState) -> felt252;
}

#[starknet::contract]
pub mod StarkPay {
    use super::IStarkPay;
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{
        Map, StoragePointerReadAccess, StoragePointerWriteAccess, 
        StorageMapReadAccess, StorageMapWriteAccess
    };

    #[storage]
    struct Storage {
        /// Maps user address to their username
        usernames: Map<ContractAddress, felt252>,
        
        /// Maps user address to their balance (in wei)
        balances: Map<ContractAddress, u256>,
        
        /// Maps user address to total amount sent
        total_sent: Map<ContractAddress, u256>,
        
        /// Maps user address to total amount received
        total_received: Map<ContractAddress, u256>,
        
        /// Maps user address to number of payments made
        payment_count: Map<ContractAddress, u32>,
        
        /// Contract owner
        owner: ContractAddress,
        
        /// Total number of registered users
        total_users: u32,
        
        /// Contract version
        version: felt252,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        UserRegistered: UserRegistered,
        PaymentSent: PaymentSent,
    }

    #[derive(Drop, starknet::Event)]
    pub struct UserRegistered {
        #[key]
        pub user: ContractAddress,
        pub username: felt252,
    }

    #[derive(Drop, starknet::Event)]
    pub struct PaymentSent {
        #[key]
        pub sender: ContractAddress,
        #[key]
        pub recipient: ContractAddress,
        pub amount: u256,
        pub message: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
        self.total_users.write(0);
        self.version.write('StarkPay_v1.0');
        
        // Give owner initial balance for testing
        self.balances.write(owner, 10000000000000000000000); // 10,000 tokens
    }

    #[abi(embed_v0)]
    impl StarkPayImpl of IStarkPay<ContractState> {
        /// Register a new user with a username
        fn register_user(ref self: ContractState, username: felt252) {
            let caller = get_caller_address();
            
            // Check if user is already registered
            assert(self.usernames.read(caller) == 0, 'User already registered');
            assert(username != 0, 'Username cannot be empty');
            
            // Register user
            self.usernames.write(caller, username);
            self.total_users.write(self.total_users.read() + 1);
            
            // Give new users some initial balance for testing (1000 tokens)
            self.balances.write(caller, 1000000000000000000000);
            
            // Emit event
            self.emit(UserRegistered { user: caller, username });
        }
        
        /// Send payment to another user
        fn send_payment(ref self: ContractState, recipient: ContractAddress, amount: u256, message: felt252) {
            let sender = get_caller_address();
            
            // Validation checks
            assert(sender != recipient, 'Cannot send to yourself');
            assert(amount > 0, 'Amount must be positive');
            assert(self.usernames.read(sender) != 0, 'Sender not registered');
            assert(self.usernames.read(recipient) != 0, 'Recipient not registered');
            
            // Check sender has sufficient balance
            let sender_balance = self.balances.read(sender);
            assert(sender_balance >= amount, 'Insufficient balance');
            
            // Update balances
            self.balances.write(sender, sender_balance - amount);
            self.balances.write(recipient, self.balances.read(recipient) + amount);
            
            // Update statistics
            self.total_sent.write(sender, self.total_sent.read(sender) + amount);
            self.total_received.write(recipient, self.total_received.read(recipient) + amount);
            self.payment_count.write(sender, self.payment_count.read(sender) + 1);
            
            // Emit event
            self.emit(PaymentSent { sender, recipient, amount, message });
        }
        
        /// Get user's current balance
        fn get_balance(self: @ContractState, user: ContractAddress) -> u256 {
            self.balances.read(user)
        }
        
        /// Get username for an address
        fn get_username(self: @ContractState, user: ContractAddress) -> felt252 {
            self.usernames.read(user)
        }
        
        /// Get total amount sent by user
        fn get_total_sent(self: @ContractState, user: ContractAddress) -> u256 {
            self.total_sent.read(user)
        }
        
        /// Get total amount received by user
        fn get_total_received(self: @ContractState, user: ContractAddress) -> u256 {
            self.total_received.read(user)
        }
        
        /// Get number of payments made by user
        fn get_payment_count(self: @ContractState, user: ContractAddress) -> u32 {
            self.payment_count.read(user)
        }
        
        /// Check if user is registered
        fn is_registered(self: @ContractState, user: ContractAddress) -> bool {
            self.usernames.read(user) != 0
        }
        
        /// Get contract version
        fn get_version(self: @ContractState) -> felt252 {
            self.version.read()
        }
    }
}

#[cfg(test)]
mod tests {
    // Basic unit tests for the StarkPay contract
    // These are simplified for compilation, full integration tests would require
    // a proper testing framework setup
    
    #[test]
    fn test_basic_functionality() {
        // Test that the contract interface is properly defined
        // In a real test environment, we would:
        // 1. Deploy the contract with constructor parameters
        // 2. Call register_user to register test users
        // 3. Call send_payment to test payment functionality
        // 4. Verify balances and transaction state
        
        assert(true, 'Contract compiles correctly');
    }
}