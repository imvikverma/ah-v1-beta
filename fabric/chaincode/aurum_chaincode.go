package main

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// AurumChaincode provides functions for managing trades and settlements
type AurumChaincode struct {
	contractapi.Contract
}

// TradeRecord represents a trade on the blockchain
type TradeRecord struct {
	TradeID    string `json:"trade_id"`
	UserID     string `json:"user_id"`
	Symbol     string `json:"symbol"`
	Side       string `json:"side"`
	Quantity   int    `json:"quantity"`
	Price      string `json:"price"`
	Timestamp  string `json:"timestamp"`
	Strategy   string `json:"strategy"`
	Status     string `json:"status"`
}

// SettlementRecord represents a settlement on the blockchain
type SettlementRecord struct {
	SettlementID string `json:"settlement_id"`
	TradeID      string `json:"trade_id"`
	UserID       string `json:"user_id"`
	Profit       string `json:"profit"`
	Status       string `json:"status"`
	Timestamp    string `json:"timestamp"`
}

// RecordTrade records a trade on the blockchain
func (s *AurumChaincode) RecordTrade(ctx contractapi.TransactionContextInterface, tradeJSON string) error {
	var trade TradeRecord
	err := json.Unmarshal([]byte(tradeJSON), &trade)
	if err != nil {
		return fmt.Errorf("failed to unmarshal trade: %v", err)
	}

	// Store trade
	tradeKey := fmt.Sprintf("TRADE:%s", trade.TradeID)
	tradeBytes, _ := json.Marshal(trade)
	err = ctx.GetStub().PutState(tradeKey, tradeBytes)
	if err != nil {
		return fmt.Errorf("failed to put trade: %v", err)
	}

	// Create composite key for user trades
	userTradeKey, err := ctx.GetStub().CreateCompositeKey("USER_TRADE", []string{trade.UserID, trade.TradeID})
	if err != nil {
		return fmt.Errorf("failed to create composite key: %v", err)
	}
	err = ctx.GetStub().PutState(userTradeKey, []byte(trade.TradeID))
	if err != nil {
		return fmt.Errorf("failed to put user trade: %v", err)
	}

	return nil
}

// RecordSettlement records a settlement on the blockchain
func (s *AurumChaincode) RecordSettlement(ctx contractapi.TransactionContextInterface, settlementJSON string) error {
	var settlement SettlementRecord
	err := json.Unmarshal([]byte(settlementJSON), &settlement)
	if err != nil {
		return fmt.Errorf("failed to unmarshal settlement: %v", err)
	}

	// Store settlement
	settlementKey := fmt.Sprintf("SETTLEMENT:%s", settlement.SettlementID)
	settlementBytes, _ := json.Marshal(settlement)
	err = ctx.GetStub().PutState(settlementKey, settlementBytes)
	if err != nil {
		return fmt.Errorf("failed to put settlement: %v", err)
	}

	return nil
}

// QueryTradeByID queries a trade by ID
func (s *AurumChaincode) QueryTradeByID(ctx contractapi.TransactionContextInterface, tradeID string) (string, error) {
	tradeKey := fmt.Sprintf("TRADE:%s", tradeID)
	tradeBytes, err := ctx.GetStub().GetState(tradeKey)
	if err != nil {
		return "", fmt.Errorf("failed to get trade: %v", err)
	}
	if tradeBytes == nil {
		return "", fmt.Errorf("trade %s does not exist", tradeID)
	}
	return string(tradeBytes), nil
}

// QueryTradesByUser queries all trades for a user
func (s *AurumChaincode) QueryTradesByUser(ctx contractapi.TransactionContextInterface, userID string) (string, error) {
	iterator, err := ctx.GetStub().GetStateByPartialCompositeKey("USER_TRADE", []string{userID})
	if err != nil {
		return "", fmt.Errorf("failed to get user trades: %v", err)
	}
	defer iterator.Close()

	var trades []TradeRecord
	for iterator.HasNext() {
		response, err := iterator.Next()
		if err != nil {
			return "", fmt.Errorf("failed to iterate: %v", err)
		}

		tradeID := string(response.Value)
		tradeKey := fmt.Sprintf("TRADE:%s", tradeID)
		tradeBytes, err := ctx.GetStub().GetState(tradeKey)
		if err != nil {
			continue
		}

		var trade TradeRecord
		json.Unmarshal(tradeBytes, &trade)
		trades = append(trades, trade)
	}

	tradesJSON, _ := json.Marshal(trades)
	return string(tradesJSON), nil
}

func main() {
	aurumChaincode, err := contractapi.NewChaincode(&AurumChaincode{})
	if err != nil {
		log.Panicf("Error creating aurum chaincode: %v", err)
	}

	if err := aurumChaincode.Start(); err != nil {
		log.Panicf("Error starting aurum chaincode: %v", err)
	}
}

