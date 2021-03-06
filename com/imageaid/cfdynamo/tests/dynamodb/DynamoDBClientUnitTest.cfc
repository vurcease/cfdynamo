component
	extends="mxunit.framework.TestCase"
	name="DynamoDBClientUnitTest"
	displayName="DynamoDB Client Unit Test"
	hint="I test the various DynamoDB interactions with application code on a unit level.  This test case implement the hard notion of unit testing.  No dependencies, all in-memory, repeatable tests with consistent results."
{



	this["name"] = "DynamoDBClientUnitTest";



	/** MXUnit Test Preparation **/



	public void function beforeTests() {
		writeLog(type="information", file="unittests", text="Starting tests for #this.name# at #now()#.");
	}


	public void function setup() {
		// Choose to use MockBox as our mocking framework
		setMockingFramework('MockBox');
		// And because I don't trust that this will actually take hold, let's explicitly instantiate MockBox
		variables.mockBox = createObject("component","mockbox.system.testing.MockBox").init();
		// Load in our credentials from the XML file
		credentials = xmlParse(expandPath("/aws_credentials.xml"));
		// Instantiate the Component Under Test (CUT) which is the DynamoDB library
		CUT = new com.imageaid.cfdynamo.DynamoDBClient(
			awsKey = credentials.cfdynamo.access_key.xmlText,
			awsSecret = credentials.cfdynamo.secret_key.xmlText
		);
	}


	/** Begin the tests **/


	/**
	 * @hint Make sure that the table name that is set in the request is the same name as the TableDescription that is in the response.
	 **/
	public void function createTableShouldSetTableName() {
		// Let's create a guaranteed unique tablename
		var stArgs = {};
		stArgs["tableName"] = "cfdynamo-unit-tests-" & createUUID();

		// Mock the Java client itself and redefine the createTable function to skip any outreach to actual AWS services,
		// and basically setup the very table information we asked it to set in the first place.
		var oAWSMock = variables.mockBox.createStub();
		oAWSMock.$("createTable", createObject("java", "com.amazonaws.services.dynamodb.model.CreateTableResult")
			.init()
			.withTableDescription(createObject("java", "com.amazonaws.services.dynamodb.model.TableDescription")
				.init()
				.withTableName(stArgs["tableName"])
				.withProvisionedThroughput(createObject("java", "com.amazonaws.services.dynamodb.model.ProvisionedThroughputDescription")
					.init()
					.withReadCapacityUnits(1)
					.withWriteCapacityUnits(1)
				)
				.withKeySchema(createObject("java", "com.amazonaws.services.dynamodb.model.KeySchema")
					.init()
					.withHashKeyElement(createObject("java", "com.amazonaws.services.dynamodb.model.KeySchemaElement")
						.init()
						.withAttributeName("testStringHashKey")
						.withAttributeType(CFMLTypeToAWSAttributeValueType("String"))
					)
				)
			)
		);
		CUT.setAwsDynamoDBClient(oAWSMock);

		// Order our CUT to perform the operation
		var stTableInfo = CUT.createTable(argumentcollection=stArgs);
		// Make sure we found our table in the list of tables
		assertEquals(stArgs["tableName"], stTableInfo["tableName"], "The resulting table description instance should be reporing a table name of '#stArgs.tableName#' but is instead reporting '#stTableInfo.tableName#'.");
	}


	/**
	 * @mxunit:expectedException "com.amazonaws.AmazonServiceException"
	 **/
	public void function createTableWithEmptyNameShouldThrowException()
	{
		// Mock the Java client itself and redefine the createTable function to skip any outreach to actual AWS services,
		// and basically setup the very table information we asked it to set in the first place.
		var oAWSMock = variables.mockBox.createStub();
		oAWSMock.$(method="createTable", throwException=true, throwType="com.amazonaws.AmazonServiceException", throwMessage="The paramater 'tableName' must be at least 3 characters long and at most 255 characters long", throwDetail="This is a mocked exception.");
		CUT.setAwsDynamoDBClient(oAWSMock);
		// Perform the testing operation
		var result = CUT.createTable(tableName="");
	}


	public void function createTableShouldAssignReadWriteThroughput() {
		// Setup an argument collection
		var stArgs = {};
		stArgs["tableName"] = "cfdynamo-unit-tests-" & createUUID();
		stArgs["readCapacity"] = 7;
		stArgs["writeCapacity"] = 3;

		// Mock the Java client itself and redefine the createTable function to skip any outreach to actual AWS services,
		// and basically setup the very table information we asked it to set in the first place.
		var oAWSMock = variables.mockBox.createStub();
		oAWSMock.$("createTable", createObject("java", "com.amazonaws.services.dynamodb.model.CreateTableResult")
			.init()
			.withTableDescription(createObject("java", "com.amazonaws.services.dynamodb.model.TableDescription")
				.init()
				.withTableName(stArgs["tableName"])
				.withProvisionedThroughput(createObject("java", "com.amazonaws.services.dynamodb.model.ProvisionedThroughputDescription")
					.init()
					.withReadCapacityUnits(stArgs["readCapacity"])
					.withWriteCapacityUnits(stArgs["writeCapacity"])
				)
				.withKeySchema(createObject("java", "com.amazonaws.services.dynamodb.model.KeySchema")
					.init()
					.withHashKeyElement(createObject("java", "com.amazonaws.services.dynamodb.model.KeySchemaElement")
						.init()
						.withAttributeName("testStringHashKey")
						.withAttributeType(CFMLTypeToAWSAttributeValueType("String"))
					)
				)
			)
		);
		CUT.setAwsDynamoDBClient(oAWSMock);

		// Create our table with custom read/write provisioning that is NOT the default values
		var stTableInfo = CUT.createTable(argumentcollection=stArgs);
		// Assert that our returned values from the serice report true
		assertEquals(stArgs["readCapacity"], stTableInfo["provisionedThroughput"]["read"], "The specified read capacity of #stArgs['readCapacity']# doesn't match the read capacity returned from the service's table description.");
		assertEquals(stArgs["writeCapacity"], stTableInfo["provisionedThroughput"]["write"], "The specified write capacity of #stArgs['writeCapacity']# doesn't match the write capacity returned from the service's table description.");
	}



	public void function tableShouldBeCreatedWithSpecifiedStringHashKey() {
		// Setup an argument collection
		var stArgs = {};
		stArgs["tableName"] = "cfdynamo-unit-tests-" & createUUID();
		stArgs["hashKeyName"] = "myTestHashKeyName";
		stArgs["hashKeyType"] = "String";

		// Mock the Java client itself and redefine the createTable function to skip any outreach to actual AWS services,
		// and basically setup the very table information we asked it to set in the first place.
		var oAWSMock = variables.mockBox.createStub();
		oAWSMock.$("createTable", createObject("java", "com.amazonaws.services.dynamodb.model.CreateTableResult")
			.init()
			.withTableDescription(createObject("java", "com.amazonaws.services.dynamodb.model.TableDescription")
				.init()
				.withKeySchema(createObject("java", "com.amazonaws.services.dynamodb.model.KeySchema")
					.init()
					.withHashKeyElement(createObject("java", "com.amazonaws.services.dynamodb.model.KeySchemaElement")
						.init()
						.withAttributeName(stArgs["hashKeyName"])
						.withAttributeType(CFMLTypeToAWSAttributeValueType(stArgs["hashKeyType"]))
					)
				)
			)
		);
		CUT.setAwsDynamoDBClient(oAWSMock);

		// Create our table with a specifically named string hash key
		var stTableInfo = CUT.createTable(argumentcollection=stArgs);
		// Take a look at the name of the hashKey, assert that it is what we specified above
		assertEquals(stArgs["hashKeyName"], stTableInfo["keys"]["hashKey"]["name"]);
		// Now assert that it is of the same data type we specified
		assertEquals(stArgs["hashKeyType"], stTableInfo["keys"]["hashKey"]["type"]);
	}


	public void function tableShouldBeCreatedWithSpecifiedNumericHashKey() {
		// Setup an argument collection
		var stArgs = {};
		stArgs["tableName"] = "cfdynamo-unit-tests-" & createUUID();
		stArgs["hashKeyName"] = "myTestHashKeyName";
		stArgs["hashKeyType"] = "Numeric";

		// Mock the Java client itself and redefine the createTable function to skip any outreach to actual AWS services,
		// and basically setup the very table information we asked it to set in the first place.
		var oAWSMock = variables.mockBox.createStub();
		oAWSMock.$("createTable", createObject("java", "com.amazonaws.services.dynamodb.model.CreateTableResult")
			.init()
			.withTableDescription(createObject("java", "com.amazonaws.services.dynamodb.model.TableDescription")
				.init()
				.withKeySchema(createObject("java", "com.amazonaws.services.dynamodb.model.KeySchema")
					.init()
					.withHashKeyElement(createObject("java", "com.amazonaws.services.dynamodb.model.KeySchemaElement")
						.init()
						.withAttributeName(stArgs["hashKeyName"])
						.withAttributeType(CFMLTypeToAWSAttributeValueType(stArgs["hashKeyType"]))
					)
				)
			)
		);
		CUT.setAwsDynamoDBClient(oAWSMock);

		// Create our table with a specifically named numeric hash key
		var stTableInfo = CUT.createTable(argumentcollection=stArgs);
		// Take a look at the name of the hashKey, assert that it is what we specified above
		assertEquals(stArgs["hashKeyName"], stTableInfo["keys"]["hashKey"]["name"]);
		// Now assert that it is of the same data type we specified
		assertEquals(stArgs["hashKeyType"], stTableInfo["keys"]["hashKey"]["type"]);
	}


	public void function tableShouldBeCreatedWithSpecifiedStringRangeKey() {
		// Setup an argument collection
		var stArgs = {};
		stArgs["tableName"] = "cfdynamo-unit-tests-" & createUUID();
		stArgs["hashKeyName"] = "myTestHashKeyName";
		stArgs["hashKeyType"] = "String";
		stArgs["rangeKeyName"] = "myTestRangeKeyName";
		stArgs["rangeKeyType"] = "String";

		// Mock the Java client itself and redefine the createTable function to skip any outreach to actual AWS services,
		// and basically setup the very table information we asked it to set in the first place.
		var oAWSMock = variables.mockBox.createStub();
		oAWSMock.$("createTable", createObject("java", "com.amazonaws.services.dynamodb.model.CreateTableResult")
			.init()
			.withTableDescription(createObject("java", "com.amazonaws.services.dynamodb.model.TableDescription")
				.init()
				.withKeySchema(createObject("java", "com.amazonaws.services.dynamodb.model.KeySchema")
					.init()
					.withHashKeyElement(createObject("java", "com.amazonaws.services.dynamodb.model.KeySchemaElement")
						.init()
						.withAttributeName(stArgs["hashKeyName"])
						.withAttributeType(CFMLTypeToAWSAttributeValueType(stArgs["hashKeyType"]))
					)
					.withRangeKeyElement(createObject("java", "com.amazonaws.services.dynamodb.model.KeySchemaElement")
						.init()
						.withAttributeName(stArgs["rangeKeyName"])
						.withAttributeType(CFMLTypeToAWSAttributeValueType(stArgs["rangeKeyType"]))
					)
				)
			)
		);
		CUT.setAwsDynamoDBClient(oAWSMock);

		// Create our table with custom named string rangeKey
		var stTableInfo = CUT.createTable(argumentcollection=stArgs);
		// Take a look at the name of the rangeKey, assert that it is what we specified above
		assertEquals(stArgs["rangeKeyName"], stTableInfo["keys"]["rangeKey"]["name"]);
		// Now assert that it is of the same data type we specified
		assertEquals(stArgs["rangeKeyType"], stTableInfo["keys"]["rangeKey"]["type"]);
	}


	public void function tableShouldBeCreatedWithSpecifiedNumericRangeKey() {
		// Setup an argument collection
		var stArgs = {};
		stArgs["tableName"] = "cfdynamo-unit-tests-" & createUUID();
		stArgs["hashKeyName"] = "myTestHashKeyName";
		stArgs["hashKeyType"] = "String";
		stArgs["rangeKeyName"] = "myTestRangeKeyName";
		stArgs["rangeKeyType"] = "Numeric";

		// Mock the Java client itself and redefine the createTable function to skip any outreach to actual AWS services,
		// and basically setup the very table information we asked it to set in the first place.
		var oAWSMock = variables.mockBox.createStub();
		oAWSMock.$("createTable", createObject("java", "com.amazonaws.services.dynamodb.model.CreateTableResult")
			.init()
			.withTableDescription(createObject("java", "com.amazonaws.services.dynamodb.model.TableDescription")
				.init()
				.withKeySchema(createObject("java", "com.amazonaws.services.dynamodb.model.KeySchema")
					.init()
					.withHashKeyElement(createObject("java", "com.amazonaws.services.dynamodb.model.KeySchemaElement")
						.init()
						.withAttributeName(stArgs["hashKeyName"])
						.withAttributeType(CFMLTypeToAWSAttributeValueType(stArgs["hashKeyType"]))
					)
					.withRangeKeyElement(createObject("java", "com.amazonaws.services.dynamodb.model.KeySchemaElement")
						.init()
						.withAttributeName(stArgs["rangeKeyName"])
						.withAttributeType(CFMLTypeToAWSAttributeValueType(stArgs["rangeKeyType"]))
					)
				)
			)
		);
		CUT.setAwsDynamoDBClient(oAWSMock);

		// Create our table with custom named string rangeKey
		var stTableInfo = CUT.createTable(argumentcollection=stArgs);
		// Take a look at the name of the rangeKey, assert that it is what we specified above
		assertEquals(stArgs["rangeKeyName"], stTableInfo["keys"]["rangeKey"]["name"]);
		// Now assert that it is of the same data type we specified
		assertEquals(stArgs["rangeKeyType"], stTableInfo["keys"]["rangeKey"]["type"]);
	}


	/** Tests for listTables **/


	public Void function listTablesShouldReturnArrayOfStrings() {
		// Mock the Java client itself and redefine the createTable function to skip any outreach to actual
		// AWS services, and basically setup the very table information we asked it to set in the first place.
		var oAWSMock = variables.mockBox.createStub();
		var aInputTableNames = ["TestTable01","TestTable02","TestTable03","TestTable04"];
		oAWSMock.$("listTables", createObject("java", "com.amazonaws.services.dynamodb.model.ListTablesResult")
			.init()
			.withTableNames(aInputTableNames)
		);
		CUT.setAwsDynamoDBClient(oAWSMock);

		// Get our table listing
		var aResultingTableNames = CUT.listTables();
		// Make sure it's an array
		assertTrue(isArray(aResultingTableNames), "The value returned from listTables is not an array!");
		// It needs to be the same array that we fed into the method
		assertEquals(aInputTableNames, aResultingTableNames, "The array of table names that came out doesn't look like the array that went in.");
	}


	/** Tests for deleteTable **/


	public Void function deleteTableShouldReportBackNameOfDeletedTable() {
		// Setup an argument collection
		var stArgs = {};
		stArgs["tableName"] = "someDeletedTableName";

		// Mock the Java client itself and redefine the createTable function to skip any outreach to actual AWS services,
		// and basically setup the very table information we asked it to set in the first place.
		var oAWSMock = variables.mockBox.createStub();
		oAWSMock.$("deleteTable", createObject("java", "com.amazonaws.services.dynamodb.model.DeleteTableResult")
			.init()
			.withTableDescription(createObject("java", "com.amazonaws.services.dynamodb.model.TableDescription")
				.init()
				.withTableName(stArgs["tableName"])
			)
		);
		CUT.setAwsDynamoDBClient(oAWSMock);

		// Delete the table
		var stDeletedTableInfo = CUT.deleteTable(argumentcollection=stArgs);
		// Make sure the name of the table that went in matches the name that came back
		assertEquals(stArgs["tableName"], stDeletedTableInfo["tableName"], "The name of the deleted table that came out doesn't match the name that went in!");
	}


	/** Tests for putItem **/


	public Void function putItemWillYieldOldRecordWhenReplacingExistingItem() {
		// Setup an argument collection
		var stArgs = {};
		stArgs["tableName"] = "someTableThatContainsExistingRecord";
		stArgs["item"] = {"id":1000, "title":"Replacement for a record that already exists", "Flavor":"vanilla"};

		// Setup the complex Java object that will represent a simulated return from the AWS put operation
		var returnedItem = createObject("java", "java.util.HashMap").init();
		returnedItem.put("id", createObject("java", "com.amazonaws.services.dynamodb.model.AttributeValue").init().withN("1000"));
		returnedItem.put("title", createObject("java", "com.amazonaws.services.dynamodb.model.AttributeValue").init().withS("Replacement for a record that already exists"));
		returnedItem.put("Flavor", createObject("java", "com.amazonaws.services.dynamodb.model.AttributeValue").init().withS("chocolate"));

		// Mock the Java client itself and redefine the createTable function to skip any outreach to actual AWS services,
		// and basically setup the very table information we asked it to set in the first place.
		var oAWSMock = variables.mockBox.createStub();
		oAWSMock.$("putItem", createObject("java", "com.amazonaws.services.dynamodb.model.PutItemResult")
			.init()
			.withAttributes(returnedItem)
		);
		CUT.setAwsDynamoDBClient(oAWSMock);

		// Perform the putItem operation. We are expecting a CFML native struct that contains the old item. In this test
		// scenario, we have updated the record from a flavor of chocolate to that of vanilla.  The old value, chocolate,
		// is what would be returned by the service according to the AWS SDK documentation.
		var stOldItem = CUT.putItem(argumentcollection=stArgs);
		// Assert that the returning structure has some keys in it, which proves it was a replacement, not a new record creation
		assertTrue(listLen(structKeyList(stOldItem)) > 0, "There are no keys in the struct that returned, which should not happen when updating an item.");
	}


	public Void function putItemWillYieldEmptyStructWhenAddingNewItem() {
		// Setup an argument collection
		var stArgs = {};
		stArgs["tableName"] = "someTableThatContainsExistingRecord";
		stArgs["item"] = {"id":1001, "title":"New record that didn't exist before", "Flavor":"strawberry"};

		// Mock the Java client itself and redefine the createTable function to skip any outreach to actual AWS services,
		// and basically setup the very table information we asked it to set in the first place.
		var oAWSMock = variables.mockBox.createStub();
		oAWSMock.$("putItem", createObject("java", "com.amazonaws.services.dynamodb.model.PutItemResult")
			.init()
		);
		CUT.setAwsDynamoDBClient(oAWSMock);

		// Perform the putItem operation. We are expecting a CFML native struct that contains the old item. In this test
		// scenario, we have updated the record from a flavor of chocolate to that of vanilla.  The old value, chocolate,
		// is what would be returned by the service according to the AWS SDK documentation.
		var stOldItem = CUT.putItem(argumentcollection=stArgs);
		// Assert that the returning structure has no keys in it, which proves it was an addition as opposed to a replacement of an old item
		assertTrue(listLen(structKeyList(stOldItem)) == 0, "There are no keys in the struct that returned, which should not happen when updating an item.");
	}


/* COMMENTED OUT - NOT ABLE TO GENERATE ByteBuffer INSTANCE FOR BINARY TESTING.
*
	public Void function connectorCorrectlyIdentifiesBinaryTypesDuringPut() {
		// Invent a new graphic image in memory we can use as binary (most likely use case)
		var byteClass = createObject("java", "java.lang.Byte").init(0).getClass();
		var byteArray = createObject("java", "java.lang.reflect.Array").newInstance(byteClass, 42);
		var byteBuffer = createObject("java", "java.nio.ByteBuffer");
		writeDump(byteArray.getClass().getCanonicalName());
		writeDump(byteBuffer);
		byteBuffer.wrap(byteArray);
		// Setup an argument collection
		var stArgs = {};
		stArgs["tableName"] = "someTableThatContainsExistingRecord";
		stArgs["item"] = {"id":1001, "binData":byteBuffer};

		// Mock the Java client itself and redefine the createTable function to skip any outreach to actual AWS services,
		// and basically setup the very table information we asked it to set in the first place.
		var oAWSMock = variables.mockBox.createStub();
		oAWSMock.$("putItem", createObject("java", "com.amazonaws.services.dynamodb.model.PutItemResult")
			.init()
		);
		CUT.setAwsDynamoDBClient(oAWSMock);

		// Perform the operation
		CUT.putItem(argumentcollection=stArgs);
		// Pull the reference to the AWS client and inspect it's mock log
		var stCallLog = CUT.getAwsDynamoDBClient().$callLog();

		writeDump(stCallLog["putItem"][1]);
		abort;

		// TODO: We need to know, via the mock log, that the type in the AttributeValue that was set
		// in the item that was put was seen by the CFML logic in the connector lib as binary data.

	}
*/


	/** Tests for getItem **/


	public Void function getItemByHashKeyWillYieldRecord() {
		// Setup an argument collection
		var stArgs = {};
		stArgs["tableName"] = "someTableThatContainsExistingRecord";
		stArgs["hashKey"] = 1000;
		stArgs["attributeNames"] = "id,title,Flavor";

		// Setup the complex Java object that will represent a simulated return from the AWS put operation
		var returnedItem = createObject("java", "java.util.HashMap").init();
		returnedItem.put("id", createObject("java", "com.amazonaws.services.dynamodb.model.AttributeValue").init().withN("1000"));
		returnedItem.put("title", createObject("java", "com.amazonaws.services.dynamodb.model.AttributeValue").init().withS("Just some record living in the DynamoDB"));
		returnedItem.put("Flavor", createObject("java", "com.amazonaws.services.dynamodb.model.AttributeValue").init().withS("chocolate"));

		// Mock the Java client itself and redefine the createTable function to skip any outreach to actual AWS services,
		// and basically setup the very table information we asked it to set in the first place.
		var oAWSMock = variables.mockBox.createStub();
		oAWSMock.$("getItem", createObject("java", "com.amazonaws.services.dynamodb.model.GetItemResult")
			.init()
			.withItem(returnedItem)
		);
		CUT.setAwsDynamoDBClient(oAWSMock);

		// Perform the getItem operation. We are expecting a CFML native struct that contains the item.
		var stItem = CUT.getItem(argumentcollection=stArgs);
		// Assert that the returning structure has some keys in it. It's not important for this test that we verify the returned
		// item matches the attributes of what was defined above. That would be for integration testing.
		assertTrue(listLen(structKeyList(stItem)) > 0, "There are no keys in the struct that returned, which should not happen when updating an item.");
	}


	public Void function getItemByHashAndRangeKeyWillYieldRecord() {
		// Setup an argument collection
		var stArgs = {};
		stArgs["tableName"] = "someTableThatContainsExistingRecord";
		stArgs["hashKey"] = 1000;
		stArgs["RangeKey"] = "SomeCrazyRangeKey";
		stArgs["attributeNames"] = "id,title,Flavor";

		// Setup the complex Java object that will represent a simulated return from the AWS put operation
		var returnedItem = createObject("java", "java.util.HashMap").init();
		returnedItem.put("id", createObject("java", "com.amazonaws.services.dynamodb.model.AttributeValue").init().withN("1000"));
		returnedItem.put("title", createObject("java", "com.amazonaws.services.dynamodb.model.AttributeValue").init().withS("Just some record living in the DynamoDB"));
		returnedItem.put("Flavor", createObject("java", "com.amazonaws.services.dynamodb.model.AttributeValue").init().withS("chocolate"));

		// Mock the Java client itself and redefine the createTable function to skip any outreach to actual AWS services,
		// and basically setup the very table information we asked it to set in the first place.
		var oAWSMock = variables.mockBox.createStub();
		oAWSMock.$("getItem", createObject("java", "com.amazonaws.services.dynamodb.model.GetItemResult")
			.init()
			.withItem(returnedItem)
		);
		CUT.setAwsDynamoDBClient(oAWSMock);

		// Perform the getItem operation. We are expecting a CFML native struct that contains the item.
		var stItem = CUT.getItem(argumentcollection=stArgs);
		// Assert that the returning structure has some keys in it. It's not important for this test that we verify the returned
		// item matches the attributes of what was defined above. That would be for integration testing.
		assertTrue(listLen(structKeyList(stItem)) > 0, "There are no keys in the struct that returned, which should not happen when updating an item.");
	}


	/** Tests for batchPutItems **/


	/**
	 * @mxunit:expectedException "API.InvalidParameters"
	 **/
	public Void function batchPutItemsShouldThrowExceptionWhenGivenZeroItems()
	{
		// Setup an argument collection
		var stArgs = {};
		stArgs["tableName"] = "someTableThatContainsExistingRecord";
		stArgs["items"] = [];
		// Perform the batch operation
		var awsBatchWriteItemResult = CUT.batchPutItems(argumentcollection=stArgs);
	}


	public Void function batchPutItemsShouldLoopOverUnprocessedItemsUntilComplete() {
		// Setup an argument collection
		var stArgs = {};
		stArgs["tableName"] = "someTableThatContainsExistingRecord";
		stArgs["items"] = [
			{"Id":300, "Name":"gumdrops", "payload":["alpha","beta","delta","gamma"], "likeChocolate":"true","cows":10}
			, {"Id":3001, "Title":"shoemonkey", "Brand":"Pepsi Co.", "likeChocolate":"false","cows":0}
			, {"Id":302, "Title":"rimbot", "Brand":"Mattel", "likeChocolate":"true","cows":42752659}
			, {"Id":303, "Title":"pony", "Brand":"Johnson & Johnson", "likeChocolate":"true","cows":559}
			, {"Id":304, "Title":"swiss", "Brand":"Nestles", "likeChocolate":"false","cows":1337}
			, {"Id":305, "Title":"Carl", "Brand":"Bughatti", "likeChocolate":"false","cows":27}
		];
		// Setup the complex Java object that will represent a simulated return from the AWS put operation
		var returnedItem = createObject("java", "java.util.HashMap").init();
		returnedItem.put("id", createObject("java", "com.amazonaws.services.dynamodb.model.AttributeValue").init().withN("1000"));
		returnedItem.put("title", createObject("java", "com.amazonaws.services.dynamodb.model.AttributeValue").init().withS("Just some record living in the DynamoDB"));
		returnedItem.put("Flavor", createObject("java", "com.amazonaws.services.dynamodb.model.AttributeValue").init().withS("chocolate"));

		// Setup our simulated request items that will report back from the DDB client
		var aAwsItems = [];
		for (var item in stArgs.items)
		{
			// Create the WriteRequest
			var awsWriteRequest = createObject("java", "com.amazonaws.services.dynamodb.model.WriteRequest")
				.init()
				.withPutRequest(createObject("java", "com.amazonaws.services.dynamodb.model.PutRequest")
					.init()
					.withItem(CUT.struct_to_dynamo_map(item))
				);
			// Now append it to our batch array
			arrayAppend(aAwsItems, awsWriteRequest);
		}

		// Mock the Java client itself and redefine the createTable function to skip any outreach to actual AWS services,
		// and basically setup the very table information we asked it to set in the first place.
		var oAWSMock = variables.mockBox.createStub();
		// Set up the batchWriteItem method in our mock to first return a result with remaining items
		// to process, and then the second time return nothing.  After our operation returns we will
		// assert that the method has been called twice.
		var oHashMapMock = variables.mockBox.createStub();
		oHashMapMock.$("getUnprocessedItems", aAwsItems);
		oHashMapMock.$("size").$results(4, 0);
		oAWSMock.$("batchWriteItem", createObject("java", "com.amazonaws.services.dynamodb.model.BatchWriteItemResult")
				.init()
				.withUnprocessedItems(oHashMapMock)
		);
		CUT.setAwsDynamoDBClient(oAWSMock);

		// Perform the batch put item operation
		CUT.batchPutItems(argumentcollection=stArgs);

		// Assert that the batchWriteItem method on our mocked client instance has been called twice
		var nCallCount = CUT.getAwsDynamoDBClient().$count("batchWriteItem");
		assertEquals(2, nCallCount, "The batchWriteItem method in our mocked DDB client should have been called twice. It has instead been called #nCallCount# times.");
	}


	/**
	 * @mxunit:expectedException "API.InvalidParameters"
	 **/
	public Void function batchDeleteItemsShouldThrowExceptionWhenGivenZeroItems()
	{
		// Setup an argument collection
		var stArgs = {};
		stArgs["tableName"] = "someTableThatContainsSomeRecords";
		stArgs["items"] = [];
		// Perform the batch operation
		var awsBatchWriteItemResult = CUT.batchDeleteItems(argumentcollection=stArgs);
	}


	public Void function batchDeleteItemsShouldLoopOverUnprocessedItemsUntilComplete() {
		// Setup an argument collection
		var stArgs = {};
		stArgs["tableName"] = "someTableThatContainsExistingRecord";
		stArgs["items"] = [
			{"hashKey":1000}
			, {"hashKey":1001}
			, {"hashKey":1002}];

		// Setup our simulated request items that will report back from the DDB client
		var aAwsItems = [];
		for (var item in stArgs.items)
		{
			// Create the WriteRequest
			var awsWriteRequest = createObject("java", "com.amazonaws.services.dynamodb.model.WriteRequest")
				.init()
				.withPutRequest(createObject("java", "com.amazonaws.services.dynamodb.model.PutRequest")
					.init()
					.withItem(CUT.struct_to_dynamo_map(item))
				);
			// Now append it to our batch array
			arrayAppend(aAwsItems, awsWriteRequest);
		}

		// Mock the Java client itself and redefine the createTable function to skip any outreach to actual AWS services,
		// and basically setup the very table information we asked it to set in the first place.
		var oAWSMock = variables.mockBox.createStub();
		// Set up the batchWriteItem method in our mock to first return a result with remaining items
		// to process, and then the second time return nothing.  After our operation returns we will
		// assert that the method has been called twice.
		var oHashMapMock = variables.mockBox.createStub();
		oHashMapMock.$("getUnprocessedItems", aAwsItems);
		oHashMapMock.$("size").$results(4, 0);
		oAWSMock.$("batchWriteItem", createObject("java", "com.amazonaws.services.dynamodb.model.BatchWriteItemResult")
				.init()
				.withUnprocessedItems(oHashMapMock)
		);
		CUT.setAwsDynamoDBClient(oAWSMock);

		// Perform the batch put item operation
		CUT.batchDeleteItems(argumentcollection=stArgs);

		// Assert that the batchWriteItem method on our mocked client instance has been called twice
		var nCallCount = CUT.getAwsDynamoDBClient().$count("batchWriteItem");
		assertEquals(2, nCallCount, "The batchWriteItem method in our mocked DDB client should have been called twice. It has instead been called #nCallCount# times.");
	}


	public Void function initWithCredentialsShouldSuccessfullyInit() {
		// Setup an argument collection
		var stArgs = {};
		stArgs["awsKey"] = "someKey";
		stArgs["awsSecret"] = "someSecret";

		// Mock the Java client itself and redefine the createTable function to skip any outreach to actual AWS services,
		// and basically setup the very table information we asked it to set in the first place.
		var oAWSMock = variables.mockBox.createStub();
		oAWSMock.$("init", createObject("java","com.amazonaws.services.dynamodb.AmazonDynamoDBClient"));
		CUT.setAwsDynamoDBClient(oAWSMock);

		// Perform the initialization
		var newCUT = CUT.init(argumentcollection=stArgs);

		// Analyze the type of object the internally set AWS DynamoDBClient has become
		var stDDB = getMetaData(CUT.getAwsDynamoDBClient());
		assertEquals("com.amazonaws.services.dynamodb.AmazonDynamoDBClient", stDDB.name, "The type reported from the CUT's awsDynamoDBClient is #stDDB.name#, as opposed to the expected: com.amazonaws.services.dynamodb.AmazonDynamoDBClient.");
	}




	/**																						**/
	/** Private helper methods, these are not tests 										**/
	/**																						**/



	/**
	 * @author Adam Bellas
	 * @displayname Convert CFML type to AWS AttributeValue Type
	 * @hint In order to properly set AttributeValue data types on the AWS SDK class instances we need to convert map CFML types to their AWS SDK equivalents.
	 **/
	private String function CFMLTypeToAWSAttributeValueType(
		required String val hint="The CFML style data type string, which will be String or Numeric")
	{
		switch (arguments.val) {
			case "String":
				return "S";
				break;
			case "Numeric":
				return "N";
				break;
			default:
				throw(type="Application.Validation", message="Unknown type, cannot convert.", detail="Only String and Numeric can be converted to AWS enumerated attribute value types at this time.");
				break;
		}
	}


	/** End of tests, begin cleanup method **/


	public void function afterTests() {
	}



/*
	public void function test_list_tables(){
		assertFalse(true,"Dang, list tables should be false.");
	}

	public void function test_create_table(){
		assertFalse(true,"Dang, create tavle also be false.");
	}

	public void function test_delete_table(){
		assertFalse(true,"Dang, delete table should be false.");
	}

	public void function test_put_item(){
		assertFalse(true,"Dang, put item should be false.");
	}

	public void function test_get_item(){
		assertFalse(true,"Dang, get item should be false.");
	}

	public void function test_update_table(){
		assertFalse(true,"Dang, update table should be false.");
	}
*/



}