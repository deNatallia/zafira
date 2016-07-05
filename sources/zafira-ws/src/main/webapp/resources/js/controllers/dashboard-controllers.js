'use strict';

ZafiraApp.controller('DashboardCtrl', [ '$scope', '$rootScope', '$http' ,'$location', 'PubNub', 'UtilService', function($scope, $rootScope, $http, $location, PubNub, UtilService) {

	$scope.UtilService = UtilService;
	$scope.testRunId = $location.search().id;
	$scope.showLoading = true;
	
	$scope.tests = {};
	$scope.testRuns = {};
	$scope.testRunResults = {};
	$scope.testRunsTestIds = {};

	$scope.testRunsToCompare = [];
	$scope.compareQueryString = "";
	$scope.totalResults = 0;
	
	$scope.testRunSearchCriteria = {
		'page' : 0,
		'pageSize' : 25
	};
	
	$scope.testSearchCriteria = {
		'page' : 0,
		'pageSize' : 100000
	};
	
	
//	$scope.initPubNub = function(){
//		$http.get('config/pubnub').success(function(config) {
//			
//			$scope.testRunsChannel = config['testRunsChannel'];
//			$scope.testsChannel = config['testsChannel'];
//			
//			PubNub.init({publish_key:config['publishKey'],subscribe_key:config['subscribeKey'],uuid:config['udid'],ssl:true});
//			
//			PubNub.ngSubscribe({channel:$scope.testsChannel});
//			PubNub.ngHistory({channel:$scope.testsChannel, count:15});
//			$scope.$on(PubNub.ngMsgEv($scope.testsChannel), function(event, payload) {
//				$scope.addTest(payload.message.test);
//				$scope.$apply();
//			});
//			
//			PubNub.ngSubscribe({channel:$scope.testRunsChannel});
//			PubNub.ngHistory({channel:$scope.testRunsChannel, count:5});
//			$scope.$on(PubNub.ngMsgEv($scope.testRunsChannel), function(event, payload) {
//				if($scope.testRunId && $scope.testRunId != payload.message.testRun.id)
//				{
//					return;
//				}
//				$scope.addTestRun(payload.message.testRun);
//				$scope.$apply();
//			});
//		});
//	};
	
	$scope.initXMPP = function(){
		$http.get('settings/xmpp').success(function(settings) {
			if(settings.enabled)
			{
				var connection = new Strophe.Connection(settings.httpBind);
				connection.connect(settings.username, settings.password, function (status) {
		            if (status === Strophe.Status.CONNECTED) {
		                 connection.addHandler(function(msg){
		                	 var elems = msg.getElementsByTagName('body');
		                	 if (elems.length > 0) 
		                	 {
		                		 var event = JSON.parse(Strophe.getText(elems[0]).replace(/&quot;/g,'"').replace(/&lt;/g,'<').replace(/&gt;/g,'>'));
		                		 console.log(event);
		                		 if(event.type == 'TEST_RUN')
	                			 {
		             				if($scope.testRunId && $scope.testRunId != event.testRun.id)
		             				{
		             					return;
		             				}
		             				$scope.addTestRun(event.testRun);
		             				$scope.$apply();
	                			 }
		                		 else if(event.type == 'TEST')
	                			 {
		             				$scope.addTest(event.test);
		             				$scope.$apply();
	                			 }
		                	 }
		                	 return true;
		                 }, null, 'message', 'chat', null,  null);
		                 connection.send($pres().tree());
		            }
		        });
			}
		}).error(function() {
			console.error('Failed to connect to XMPP');
		});
	};
	
	$scope.addTest = function(test) {
		if($scope.tests[test.id] == null)
    	{
    		$scope.tests[test.testRunId] = {};
    	}
		if($scope.testRunsTestIds[test.testRunId] == null)
    	{
			$scope.testRunsTestIds[test.testRunId] = [];
    	}
    	if($scope.testRunsTestIds[test.testRunId].indexOf(test.id) < 0)
    	{
    		$scope.testRunsTestIds[test.testRunId].push(test.id)
    	}
    	// Remove previous result
    	if($scope.tests[test.id] != null)
    	{
    		$scope.updateTestRunResults($scope.tests[test.id], -1);
    	}
    	$scope.tests[test.id] = test;
    	$scope.initTestRunResults(test.testRunId);
    	$scope.updateTestRunResults($scope.tests[test.id], 1);
	};
	
	$scope.updateTestRunResults = function(test, amount) {
		switch(test.status) {
			case "PASSED":
				$scope.testRunResults[test.testRunId].passed = $scope.testRunResults[test.testRunId].passed + amount;
				break;
			case "FAILED":
				$scope.testRunResults[test.testRunId].failed = $scope.testRunResults[test.testRunId].failed + amount;
				break;
			case "SKIPPED":
				$scope.testRunResults[test.testRunId].skipped = $scope.testRunResults[test.testRunId].skipped + amount;
				break;
			case "IN_PROGRESS":
				$scope.testRunResults[test.testRunId].in_progress = $scope.testRunResults[test.testRunId].in_progress + amount;
				break;
		}
	};
	
	$scope.addTestRun = function(testRun) {
		testRun.showDetails = $scope.testRunId ? true : false;
    	if($scope.testRuns[testRun.id] == null)
    	{
    		testRun.jenkinsURL = testRun.job.jobURL + "/" + testRun.buildNumber;
    		testRun.UID = testRun.testSuite.name + " " + testRun.jenkinsURL
    		$scope.testRuns[testRun.id] = testRun;
    		$scope.initTestRunResults(testRun.id);
    	}
    	else
    	{
    		$scope.testRuns[testRun.id].status = testRun.status;
    	}
	};
	
	$scope.initTestRunResults = function(testRunId) {
		if($scope.testRunResults[testRunId] == null)
    	{
			$scope.testRunResults[testRunId] = {};
			$scope.testRunResults[testRunId].passed = 0;
			$scope.testRunResults[testRunId].failed = 0;
			$scope.testRunResults[testRunId].skipped = 0;
			$scope.testRunResults[testRunId].in_progress = 0;
    	}
	};
	
	$scope.getArgValue = function(xml, key){
		try
		{
			var xmlDoc = new DOMParser().parseFromString(xml,"text/xml");
			var args = xmlDoc.getElementsByTagName("config")[0].childNodes;
			for(var i = 0; i < args.length; i++)
			{
				if(args[i].getElementsByTagName("key")[0].innerHTML == key)
				{
					return args[i].getElementsByTagName("value")[0].innerHTML;
				}
			}
		}
		catch(err)
		{
			console.log("Environment arg not retrieved!");
		}
		return null;
	};
	
	$scope.selectTestRun = function(id, isChecked) {		 
		if(isChecked == "true") {
			$scope.testRunsToCompare.push(id);
		} else {
			var idx = $scope.testRunsToCompare.indexOf(id);
			if(idx > -1){
				$scope.testRunsToCompare.splice(idx, 1);
			}
		}
		$scope.compareQueryString = "";
		for(var i = 0; i < $scope.testRunsToCompare.length; i++)
		{
			$scope.compareQueryString = $scope.compareQueryString + $scope.testRunsToCompare[i];
			if(i < $scope.testRunsToCompare.length - 1)
			{
				$scope.compareQueryString = $scope.compareQueryString + "+";
			}
		}
	};
	
	$scope.loadTestRuns = function(page, pageSize){
		$scope.testRunSearchCriteria.page = page;
		if(pageSize)
		{
			$scope.testRunSearchCriteria.pageSize = pageSize;
		}
		if($scope.testRunId)
		{
			$scope.testRunSearchCriteria.id = $scope.testRunId;
		}
		$http.post('tests/runs/search', $scope.testRunSearchCriteria).success(function(data) {
			$scope.testRunSearchCriteria.page = data.page;
			$scope.testRunSearchCriteria.pageSize = data.pageSize;
			$scope.totalResults = data.totalResults;
			
			var testRunIds = [];
			for(var i = 0; i < data.results.length; i ++)
			{
				testRunIds.push(data.results[i].id);
				$scope.addTestRun(data.results[i]);
			}
			
			$scope.loadTests(testRunIds);
			
		}).error(function() {
			console.error('Failed to search test runs');
		});
	};
	
	$scope.loadTests = function(testRunIds){
		$scope.testSearchCriteria.testRunIds = testRunIds;
		$http.post('tests/search', $scope.testSearchCriteria).success(function(data) {
			$scope.userSearchResult = data;
			$scope.testSearchCriteria.page = data.page;
			$scope.testSearchCriteria.pageSize = data.pageSize;
			
			for(var i = 0; i < data.results.length; i ++)
			{
				$scope.addTest(data.results[i]);
			}
			
		}).error(function() {
			console.error('Failed to search tests');
		});
	};
	
	(function init(){
		$scope.initXMPP();
		$scope.loadTestRuns(0);

		setTimeout(function() {  
			$scope.$apply(function () {
				$scope.showLoading = false;
			});
		}, 30000);
	})();
	
	$scope.menuOptions = [
      ['Open', function ($itemScope) {
          window.open($location.$$absUrl + "?id=" + $itemScope.testRun.id, '_blank');
      }],
      null,
      ['Copy link', function ($itemScope) {
    	  	var node = document.createElement('pre');
	  	    node.textContent = $location.$$absUrl + "?id=" + $itemScope.testRun.id;
	  	    document.body.appendChild(node);
	  	    
	  	    var selection = getSelection();
	  	    selection.removeAllRanges();
	
	  	    var range = document.createRange();
	  	    range.selectNodeContents(node);
	  	    selection.addRange(range);
	
	  	    document.execCommand('copy');
	  	    selection.removeAllRanges();
	  	    document.body.removeChild(node);
      }]
    ];
	
} ]);
