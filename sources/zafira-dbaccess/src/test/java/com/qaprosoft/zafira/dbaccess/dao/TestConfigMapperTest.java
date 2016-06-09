package com.qaprosoft.zafira.dbaccess.dao;

import static org.testng.Assert.assertEquals;
import static org.testng.Assert.assertNotEquals;
import static org.testng.Assert.assertNull;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.testng.AbstractTestNGSpringContextTests;
import org.testng.annotations.Test;

import com.qaprosoft.zafira.dbaccess.dao.mysql.TestConfigMapper;
import com.qaprosoft.zafira.dbaccess.model.TestConfig;

@Test
@ContextConfiguration("classpath:com/qaprosoft/zafira/dbaccess/dbaccess-test.xml")
public class TestConfigMapperTest extends AbstractTestNGSpringContextTests
{
	/**
	 * Turn this on to enable this test
	 */
	private static final boolean ENABLED = false;
	
	private static final TestConfig TEST_CONFIG = new TestConfig()
	{
		private static final long serialVersionUID = 1L;
		{
			setUrl("http://localhost:8080");
			setEnv("QA");
			setPlatform("iOS");
			setPlatformVersion("9.1");
			setBrowser("chrome");
			setBrowserVersion("43");
			setAppVersion("1.1");
			setLocale("en");
			setLanguage("GB");
			setDevice("Samsung Galaxy S3");
		}
	};

	@Autowired
	private TestConfigMapper testConfigMapper;

	@Test(enabled = ENABLED)
	public void createTestConfig()
	{
		testConfigMapper.createTestConfig(TEST_CONFIG);
		assertNotEquals(TEST_CONFIG.getId(), 0, "Test config ID must be set up by autogenerated keys");
	}

	@Test(enabled = ENABLED, dependsOnMethods =
	{ "createTestConfig" })
	public void getTestConfigById()
	{
		checkTestConfig(testConfigMapper.getTestConfigById(TEST_CONFIG.getId()));
	}

	@Test(enabled = ENABLED, dependsOnMethods = { "createTestConfig" })
	public void updateTestConfig()
	{
		TEST_CONFIG.setUrl("http://localhost:8081");
		TEST_CONFIG.setEnv("PROD");
		TEST_CONFIG.setPlatform("Android");
		TEST_CONFIG.setPlatformVersion("5.0.1");
		TEST_CONFIG.setBrowser("firefox");
		TEST_CONFIG.setBrowserVersion("32");
		TEST_CONFIG.setAppVersion("1.2");
		TEST_CONFIG.setLocale("fr");
		TEST_CONFIG.setLanguage("FR");
		TEST_CONFIG.setDevice("Samsung Galaxy S4");
		
		testConfigMapper.updateTestConfig(TEST_CONFIG);

		checkTestConfig(testConfigMapper.getTestConfigById(TEST_CONFIG.getId()));
	}

	/**
	 * Turn this in to delete test after all tests
	 */
	private static final boolean DELETE_ENABLED = true;

	@Test(enabled = ENABLED && DELETE_ENABLED , dependsOnMethods = { "createTestConfig", "getTestConfigById", "updateTestConfig" })
	public void deleteTestConfig()
	{
		testConfigMapper.deleteTestConfigById(TEST_CONFIG.getId());

		assertNull(testConfigMapper.getTestConfigById(TEST_CONFIG.getId()));
	}

	private void checkTestConfig(TestConfig testConfig)
	{
		assertEquals(testConfig.getUrl(), TEST_CONFIG.getUrl(), "URL must match");
		assertEquals(testConfig.getEnv(), TEST_CONFIG.getEnv(), "Env must match");
		assertEquals(testConfig.getPlatform(), TEST_CONFIG.getPlatform(), "Platform must match");
		assertEquals(testConfig.getPlatformVersion(), TEST_CONFIG.getPlatformVersion(), "Platform version must match");
		assertEquals(testConfig.getBrowser(), TEST_CONFIG.getBrowser(), "Browser must match");
		assertEquals(testConfig.getBrowserVersion(), TEST_CONFIG.getBrowserVersion(), "Browser version must match");
		assertEquals(testConfig.getLocale(), TEST_CONFIG.getLocale(), "Locale must match");
		assertEquals(testConfig.getLanguage(), TEST_CONFIG.getLanguage(), "Language must match");
		assertEquals(testConfig.getDevice(), TEST_CONFIG.getDevice(), "Device must match");
	}
}