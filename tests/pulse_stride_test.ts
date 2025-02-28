import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test challenge creation and retrieval",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('pulse-stride', 'create-challenge',
        [types.ascii("Test Challenge"), types.uint(10000), types.uint(30)],
        deployer.address
      )
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
    
    const challenge = chain.callReadOnlyFn(
      'pulse-stride',
      'get-challenge',
      [types.uint(1)],
      deployer.address
    );
    
    challenge.result.expectSome();
  }
});

Clarinet.test({
  name: "Test challenge participation flow",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const participant = accounts.get('wallet_1')!;
    
    // Create challenge
    let block = chain.mineBlock([
      Tx.contractCall('pulse-stride', 'create-challenge',
        [types.ascii("Test Challenge"), types.uint(10000), types.uint(30)],
        deployer.address
      )
    ]);
    
    // Join challenge
    block = chain.mineBlock([
      Tx.contractCall('pulse-stride', 'join-challenge',
        [types.uint(1)],
        participant.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Record steps
    block = chain.mineBlock([
      Tx.contractCall('pulse-stride', 'record-steps',
        [types.uint(1), types.uint(5000)],
        participant.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Check progress
    const progress = chain.callReadOnlyFn(
      'pulse-stride',
      'get-progress',
      [types.uint(1), types.principal(participant.address)],
      participant.address
    );
    progress.result.expectOk().expectUint(5000);
  }
});

Clarinet.test({
  name: "Test error conditions",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const participant = accounts.get('wallet_1')!;
    
    // Try to join non-existent challenge
    let block = chain.mineBlock([
      Tx.contractCall('pulse-stride', 'join-challenge',
        [types.uint(999)],
        participant.address
      )
    ]);
    block.receipts[0].result.expectErr().expectUint(101);
    
    // Create and join challenge
    block = chain.mineBlock([
      Tx.contractCall('pulse-stride', 'create-challenge',
        [types.ascii("Test Challenge"), types.uint(10000), types.uint(30)],
        deployer.address
      )
    ]);
    
    block = chain.mineBlock([
      Tx.contractCall('pulse-stride', 'join-challenge',
        [types.uint(1)],
        participant.address
      )
    ]);
    
    // Try to join same challenge again
    block = chain.mineBlock([
      Tx.contractCall('pulse-stride', 'join-challenge',
        [types.uint(1)],
        participant.address
      )
    ]);
    block.receipts[0].result.expectErr().expectUint(102);
    
    // Try to record invalid steps
    block = chain.mineBlock([
      Tx.contractCall('pulse-stride', 'record-steps',
        [types.uint(1), types.uint(200000)],
        participant.address
      )
    ]);
    block.receipts[0].result.expectErr().expectUint(104);
  }
});
