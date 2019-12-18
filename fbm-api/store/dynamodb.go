package store

import (
	"context"
	"encoding/json"
	"strconv"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
)

type DynamoDBStore struct {
	FBDataStore
	table *string
	svc   *dynamodb.DynamoDB
}

type fbData struct {
	Key       string      `dynamodbav:"key"`
	Timestamp uint64      `dynamodbav:"timestamp"`
	Data      interface{} `dynamodbav:"data"`
}

func NewDynamoDBStore(config *aws.Config, tablename string) (*DynamoDBStore, error) {
	sess, err := session.NewSession(config)
	if err != nil {
		return nil, err
	}

	// Create DynamoDB client
	svc := dynamodb.New(sess)

	return &DynamoDBStore{
		table: aws.String(tablename),
		svc:   svc,
	}, nil
}

func (d *DynamoDBStore) AddFBStat(ctx context.Context, key string, timestamp uint64, value interface{}) error {
	data, err := json.Marshal(value)
	if err != nil {
		return err
	}
	info := fbData{
		Key:       key,
		Timestamp: timestamp,
		Data:      data,
	}

	item, err := dynamodbattribute.MarshalMap(info)
	if err != nil {
		return err
	}

	_, err = d.svc.PutItem(&dynamodb.PutItemInput{
		TableName: d.table,
		Item:      item,
	})

	return err
}

func (d *DynamoDBStore) GetFBStat(ctx context.Context, key string, from, to uint64) ([]interface{}, error) {
	input := &dynamodb.QueryInput{
		TableName: d.table,
		KeyConditions: map[string]*dynamodb.Condition{
			"timestamp": {
				ComparisonOperator: aws.String("BETWEEN"),
				AttributeValueList: []*dynamodb.AttributeValue{
					{
						N: aws.String(strconv.FormatUint(from, 10)),
					},
					{
						N: aws.String(strconv.FormatUint(to, 10)),
					},
				},
			},
		},
	}
	result, err := d.svc.Query(input)
	if err != nil {
		return nil, err
	}

	var items []interface{}

	if err := dynamodbattribute.UnmarshalListOfMaps(result.Items, &items); err != nil {
		return nil, err
	}

	return items, nil
}
