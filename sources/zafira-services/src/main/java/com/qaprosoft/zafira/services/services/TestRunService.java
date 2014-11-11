package com.qaprosoft.zafira.services.services;

import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.qaprosoft.zafira.dbaccess.dao.mysql.TestRunMapper;
import com.qaprosoft.zafira.dbaccess.model.TestRun;
import com.qaprosoft.zafira.dbaccess.model.TestRun.Status;
import com.qaprosoft.zafira.dbaccess.model.User;
import com.qaprosoft.zafira.services.exceptions.InvalidTestRunException;
import com.qaprosoft.zafira.services.exceptions.ServiceException;

@Service
public class TestRunService
{
	@Autowired
	private TestRunMapper testRunMapper;
	
	@Autowired
	private UserService userService;
	
	@Transactional(rollbackFor = Exception.class)
	public void createTestRun(TestRun testRun) throws ServiceException
	{
		testRunMapper.createTestRun(testRun);
	}
	
	@Transactional(readOnly = true)
	public TestRun getTestRunById(long id) throws ServiceException
	{
		return testRunMapper.getTestRunById(id);
	}
	
	@Transactional(rollbackFor = Exception.class)
	public TestRun updateTestRun(TestRun testRun) throws ServiceException
	{
		testRunMapper.updateTestRun(testRun);
		return testRun;
	}
	
	@Transactional(rollbackFor = Exception.class)
	public void deleteTestRun(TestRun testRun) throws ServiceException
	{
		testRunMapper.deleteTestRun(testRun);
	}
	
	@Transactional(rollbackFor = Exception.class)
	public TestRun initializeTestRun(TestRun newTestRun) throws ServiceException
	{
		switch (newTestRun.getStartedBy())
		{
			case HUMAN:
				if(newTestRun.getUser() == null || StringUtils.isEmpty(newTestRun.getUser().getUserName()))
				{
					throw new InvalidTestRunException("Specify userName if started by HUMAN!");
				}
				User user = userService.createUser(newTestRun.getUser().getUserName());
				newTestRun.setUser(user);
				break;
			case SCHEDULER:
				newTestRun.setBuildNumber(null);
				newTestRun.setUpstreamJob(null);
				newTestRun.setUser(null);
				break;
			case UPSTREAM_JOB:
				if(newTestRun.getUpstreamJob() == null || newTestRun.getUpstreamJobBuildNumber() == null)
				{
					throw new InvalidTestRunException("Specify upstreamJobId and upstreaBuildNumber if started by UPSTREAM_JOB!");
				}
				newTestRun.setUser(null);
				break;
		}
		newTestRun.setStatus(Status.IN_PROGRESS);
		createTestRun(newTestRun);
		return newTestRun;
	}
}