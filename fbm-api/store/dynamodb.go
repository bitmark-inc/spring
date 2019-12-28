package store

import (
	"context"
	"encoding/json"
	"errors"
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
	Key       string `dynamodbav:"key"`
	Timestamp int64  `dynamodbav:"timestamp"`
	Data      []byte `dynamodbav:"data"`
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

func (d *DynamoDBStore) AddFBStat(ctx context.Context, key string, timestamp int64, value interface{}) error {
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

// FBStat represent a statistic record for Facebook data that will be push to dynamodb
type FBStat struct {
	Key       string
	Timestamp int64
	Value     interface{}
}

// AddFBStats will push all of the statistic records in stats array to dynamo DB
func (d *DynamoDBStore) AddFBStats(ctx context.Context, stats []FBStat) error {
	if len(stats) > 25 {
		return errors.New("can not push more than 25 records at once for dynamodb")
	}

	writeRequests := make([]*dynamodb.WriteRequest, 0)

	for _, stat := range stats {
		data, err := json.Marshal(stat.Value)
		if err != nil {
			return err
		}
		info := fbData{
			Key:       stat.Key,
			Timestamp: stat.Timestamp,
			Data:      data,
		}
		item, err := dynamodbattribute.MarshalMap(info)
		if err != nil {
			return err
		}

		writeRequests = append(writeRequests, &dynamodb.WriteRequest{
			PutRequest: &dynamodb.PutRequest{
				Item: item,
			},
		})
	}

	input := &dynamodb.BatchWriteItemInput{
		RequestItems: map[string][]*dynamodb.WriteRequest{
			*d.table: writeRequests,
		},
	}

	_, err := d.svc.BatchWriteItem(input)
	return err
}

func (d *DynamoDBStore) queryFBStatResult(input *dynamodb.QueryInput) ([]interface{}, error) {
	result, err := d.svc.Query(input)
	if err != nil {
		return nil, err
	}

	var items []fbData

	if err := dynamodbattribute.UnmarshalListOfMaps(result.Items, &items); err != nil {
		return nil, err
	}

	var data []interface{}
	for _, i := range items {
		var d interface{}
		if err := json.Unmarshal(i.Data, &d); err != nil {
			return nil, err
		}
		data = append(data, d)
	}

	return data, nil
}

func (d *DynamoDBStore) GetFBStat(ctx context.Context, key string, from, to int64) ([]interface{}, error) {
	input := &dynamodb.QueryInput{
		TableName: d.table,
		KeyConditions: map[string]*dynamodb.Condition{
			"key": {
				ComparisonOperator: aws.String("EQ"),
				AttributeValueList: []*dynamodb.AttributeValue{
					{
						S: aws.String(key),
					},
				},
			},
			"timestamp": {
				ComparisonOperator: aws.String("BETWEEN"),
				AttributeValueList: []*dynamodb.AttributeValue{
					{
						N: aws.String(strconv.FormatInt(from, 10)),
					},
					{
						N: aws.String(strconv.FormatInt(to, 10)),
					},
				},
			},
		},
	}

	return d.queryFBStatResult(input)
}

func (d *DynamoDBStore) GetFBFirstItem(ctx context.Context, key string) (interface{}, error) {
	input := &dynamodb.QueryInput{
		TableName: d.table,
		KeyConditions: map[string]*dynamodb.Condition{
			"key": {
				ComparisonOperator: aws.String("EQ"),
				AttributeValueList: []*dynamodb.AttributeValue{
					{
						S: aws.String(key),
					},
				},
			},
		},
		Limit:            aws.Int64(1),
		ScanIndexForward: aws.Bool(true),
	}

	return d.queryFBStatResult(input)
}

func (d *DynamoDBStore) GetExactFBStat(ctx context.Context, key string, in int64) (interface{}, error) {
	input := &dynamodb.QueryInput{
		TableName: d.table,
		KeyConditions: map[string]*dynamodb.Condition{
			"key": {
				ComparisonOperator: aws.String("EQ"),
				AttributeValueList: []*dynamodb.AttributeValue{
					{
						S: aws.String(key),
					},
				},
			},
			"timestamp": {
				ComparisonOperator: aws.String("EQ"),
				AttributeValueList: []*dynamodb.AttributeValue{
					{
						N: aws.String(strconv.FormatInt(in, 10)),
					},
				},
			},
		},
	}
	result, err := d.svc.Query(input)
	if err != nil {
		return nil, err
	}

	var items []fbData

	if err := dynamodbattribute.UnmarshalListOfMaps(result.Items, &items); err != nil {
		return nil, err
	}

	if len(items) != 1 {
		return nil, nil
	}

	var data interface{}
	if err := json.Unmarshal(items[0].Data, &data); err != nil {
		return nil, err
	}

	return data, nil
}
