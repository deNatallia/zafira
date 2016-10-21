﻿CREATE SCHEMA IF NOT EXISTS zafira;

SET SCHEMA 'zafira';

DROP FUNCTION IF EXISTS update_timestamp();
CREATE FUNCTION update_timestamp() RETURNS trigger AS $update_timestamp$
    BEGIN
        NEW.modified_at := current_timestamp;
        RETURN NEW;
    END;
$update_timestamp$ LANGUAGE plpgsql;

DROP TABLE IF EXISTS USERS;
CREATE TABLE USERS (
  ID SERIAL,
  USERNAME VARCHAR(100) NOT NULL,
  PASSWORD VARCHAR(50) NULL DEFAULT '',
  EMAIL VARCHAR(100) NULL,
  FIRST_NAME VARCHAR(100) NULL,
  LAST_NAME VARCHAR(100) NULL,
  MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID));
CREATE UNIQUE INDEX USERNAME_UNIQUE ON USERS (USERNAME);
CREATE TRIGGER update_timestamp_users BEFORE INSERT OR UPDATE ON USERS
    FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


DROP TABLE IF EXISTS TEST_SUITES;
CREATE TABLE IF NOT EXISTS TEST_SUITES (
  ID SERIAL,
  NAME VARCHAR(200) NOT NULL,
  DESCRIPTION TEXT NULL,
  FILE_NAME VARCHAR(255) NOT NULL DEFAULT '',
  USER_ID INT NOT NULL,
  MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID),
  CONSTRAINT fk_TEST_SUITES_USERS1
    FOREIGN KEY (USER_ID)
    REFERENCES USERS (ID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
CREATE UNIQUE INDEX NAME_FILE_USER_UNIQUE ON TEST_SUITES (NAME, FILE_NAME, USER_ID);
CREATE INDEX FK_TEST_SUITE_USER_ASC ON TEST_SUITES (USER_ID);
CREATE TRIGGER update_timestamp_test_suits BEFORE INSERT OR UPDATE ON TEST_SUITES
    FOR EACH ROW EXECUTE PROCEDURE update_timestamp();



DROP TABLE IF EXISTS PROJECTS;
CREATE TABLE IF NOT EXISTS PROJECTS (
  ID SERIAL,
  NAME VARCHAR(255) NOT NULL,
  DESCRIPTION TEXT NULL,
  MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID));
CREATE UNIQUE INDEX NAME_UNIQUE ON PROJECTS (NAME);
CREATE TRIGGER update_timestamp_projects BEFORE INSERT OR UPDATE ON PROJECTS
    FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


DROP TABLE IF EXISTS TEST_CASES;
CREATE TABLE IF NOT EXISTS TEST_CASES (
  ID SERIAL,
  TEST_CLASS VARCHAR(255) NOT NULL,
  TEST_METHOD VARCHAR(100) NOT NULL,
  INFO TEXT NULL,
  TEST_SUITE_ID INT NOT NULL,
  USER_ID INT NOT NULL,
  PROJECT_ID INT NULL,
  STATUS VARCHAR(20) NOT NULL DEFAULT 'UNKNOWN',
  MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID),
  CONSTRAINT fk_TEST_CASE_TEST_SUITE1
    FOREIGN KEY (TEST_SUITE_ID)
    REFERENCES TEST_SUITES (ID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_TEST_CASES_USERS1
    FOREIGN KEY (USER_ID)
    REFERENCES USERS (ID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_TEST_CASES_PROJECTS1
    FOREIGN KEY (PROJECT_ID)
    REFERENCES PROJECTS (ID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
CREATE INDEX FK_TEST_CASE_SUITE_ASC ON TEST_CASES (TEST_SUITE_ID);
CREATE INDEX FK_TEST_CASE_USER_ASC ON TEST_CASES (USER_ID);
CREATE INDEX FK_TEST_CASES_PROJECTS_ASC ON TEST_CASES (PROJECT_ID);
CREATE TRIGGER update_timestamp_test_cases BEFORE INSERT OR UPDATE ON TEST_CASES
    FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


DROP TABLE IF EXISTS WORK_ITEMS;
CREATE TABLE IF NOT EXISTS WORK_ITEMS (
  ID SERIAL,
  JIRA_ID VARCHAR(45) NOT NULL,
  TYPE VARCHAR(45) NOT NULL DEFAULT 'TASK',
  HASH_CODE INT NULL,
  DESCRIPTION TEXT NULL,
  USER_ID INT NULL,
  TEST_CASE_ID INT NULL,
  KNOWN_ISSUE BOOLEAN NOT NULL DEFAULT FALSE,
  MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID),
  CONSTRAINT fk_WORK_ITEMS_USERS1
    FOREIGN KEY (USER_ID)
    REFERENCES USERS (ID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_WORK_ITEMS_TEST_CASES1
    FOREIGN KEY (TEST_CASE_ID)
    REFERENCES TEST_CASES (ID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
CREATE UNIQUE INDEX WORK_ITEM_UNIQUE ON WORK_ITEMS (JIRA_ID, TYPE, HASH_CODE);
CREATE INDEX FK_WORK_ITEM_USER_ASC ON WORK_ITEMS (USER_ID);
CREATE INDEX FK_WORK_ITEM_TEST_CASE_ASC ON WORK_ITEMS (TEST_CASE_ID);
CREATE TRIGGER update_timestamp_work_items BEFORE INSERT OR UPDATE ON WORK_ITEMS
    FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


DROP TABLE IF EXISTS JOBS;
CREATE TABLE IF NOT EXISTS JOBS (
  ID SERIAL,
  USER_ID INT NULL,
  NAME VARCHAR(100) NOT NULL,
  JOB_URL VARCHAR(255) NOT NULL,
  JENKINS_HOST VARCHAR(255) NULL,
  MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID),
  CONSTRAINT fk_JOBS_USERS1
    FOREIGN KEY (USER_ID)
    REFERENCES USERS (ID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
CREATE UNIQUE INDEX JOB_URL_UNIQUE ON JOBS (JOB_URL);
CREATE INDEX fk_JOBS_USERS1_idx ON JOBS (USER_ID);
CREATE TRIGGER update_timestamp_jobs BEFORE INSERT OR UPDATE ON JOBS FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


DROP TABLE IF EXISTS TEST_RUNS;
CREATE TABLE IF NOT EXISTS TEST_RUNS (
  ID SERIAL,
  CI_RUN_ID VARCHAR(50) NULL,
  USER_ID INT,
  TEST_SUITE_ID INT NOT NULL,
  STATUS VARCHAR(20) NOT NULL,
  SCM_URL VARCHAR(255) NULL,
  SCM_BRANCH VARCHAR(100) NULL,
  SCM_COMMIT VARCHAR(100) NULL,
  CONFIG_XML TEXT NULL,
  WORK_ITEM_ID INT NULL,
  JOB_ID INT NOT NULL,
  BUILD_NUMBER INT NOT NULL,
  STARTED_BY VARCHAR(45) NULL,
  UPSTREAM_JOB_ID INT  NULL,
  UPSTREAM_JOB_BUILD_NUMBER INT NULL,
  PROJECT_ID INT NULL,
  MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID),
  CONSTRAINT fk_TEST_RESULTS_USERS1
    FOREIGN KEY (USER_ID)
    REFERENCES USERS (ID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_TEST_RESULTS_TEST_SUITES1
    FOREIGN KEY (TEST_SUITE_ID)
    REFERENCES TEST_SUITES (ID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_TEST_RUNS_WORK_ITEMS1
    FOREIGN KEY (WORK_ITEM_ID)
    REFERENCES WORK_ITEMS (ID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_TEST_RUNS_JOBS1
    FOREIGN KEY (JOB_ID)
    REFERENCES JOBS (ID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_TEST_RUNS_JOBS2
    FOREIGN KEY (UPSTREAM_JOB_ID)
    REFERENCES JOBS (ID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_TEST_RUNS_PROJECTS1
    FOREIGN KEY (PROJECT_ID)
    REFERENCES PROJECTS (ID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
CREATE INDEX FK_TEST_RUN_USER_ASC ON TEST_RUNS (USER_ID);
CREATE INDEX FK_TEST_RUN_TEST_SUITE_ASC ON TEST_RUNS (TEST_SUITE_ID);
CREATE INDEX fk_TEST_RUNS_WORK_ITEMS1_idx ON TEST_RUNS (WORK_ITEM_ID);
CREATE INDEX fk_TEST_RUNS_JOBS1_idx ON TEST_RUNS (JOB_ID);
CREATE INDEX fk_TEST_RUNS_JOBS2_idx ON TEST_RUNS (UPSTREAM_JOB_ID);
CREATE INDEX fk_TEST_RUNS_PROJECTS1_idx ON TEST_RUNS (PROJECT_ID);
CREATE UNIQUE INDEX CI_RUN_ID_UNIQUE ON TEST_RUNS (CI_RUN_ID);
CREATE TRIGGER update_timestamp_test_runs BEFORE INSERT OR UPDATE ON TEST_RUNS FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


DROP TABLE IF EXISTS TEST_CONFIGS;
CREATE TABLE IF NOT EXISTS TEST_CONFIGS (
  ID SERIAL,
  URL VARCHAR(512) NULL,
  ENV VARCHAR(50) NULL,
  PLATFORM VARCHAR(30) NULL,
  PLATFORM_VERSION VARCHAR(30) NULL,
  BROWSER VARCHAR(30) NULL,
  BROWSER_VERSION VARCHAR(30) NULL,
  APP_VERSION VARCHAR(255) NULL,
  LOCALE VARCHAR(30) NULL,
  LANGUAGE VARCHAR(30) NULL,
  DEVICE VARCHAR(50) NULL,
  MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID));
CREATE TRIGGER update_timestamp_test_configs BEFORE INSERT OR UPDATE ON TEST_CONFIGS FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


DROP TABLE IF EXISTS TESTS;
CREATE TABLE IF NOT EXISTS TESTS (
  ID SERIAL,
  NAME VARCHAR(255) NOT NULL,
  STATUS VARCHAR(20) NOT NULL,
  TEST_ARGS TEXT NULL,
  TEST_RUN_ID INT NOT NULL,
  TEST_CASE_ID INT NOT NULL,
  MESSAGE TEXT NULL,
  START_TIME TIMESTAMP NULL,
  FINISH_TIME TIMESTAMP NULL,
  DEMO_URL TEXT NULL,
  LOG_URL TEXT NULL,
  RETRY INT NOT NULL DEFAULT 0,
  TEST_CONFIG_ID INT NULL,
  MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID),
  CONSTRAINT fk_TESTS_TEST_CONFIGS1
    FOREIGN KEY (TEST_CONFIG_ID)
    REFERENCES TEST_CONFIGS (ID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_TESTS_TEST_RUNS1
    FOREIGN KEY (TEST_RUN_ID)
    REFERENCES TEST_RUNS (ID)
    ON DELETE CASCADE
    ON UPDATE NO ACTION,
  CONSTRAINT fk_TESTS_TEST_CASES1
    FOREIGN KEY (TEST_CASE_ID)
    REFERENCES TEST_CASES (ID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
CREATE INDEX fk_TESTS_TEST_RUNS1_idx ON  TESTS (TEST_RUN_ID);
CREATE INDEX fk_TESTS_TEST_CASES1_idx ON  TESTS (TEST_CASE_ID);
CREATE INDEX fk_TESTS_TEST_CONFIGS1_idx ON TESTS (TEST_CONFIG_ID);
CREATE TRIGGER update_timestamp_tests BEFORE INSERT OR UPDATE ON TESTS FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


DROP TABLE IF EXISTS TEST_WORK_ITEMS;
CREATE TABLE IF NOT EXISTS TEST_WORK_ITEMS (
  ID SERIAL,
  TEST_ID INT NOT NULL,
  WORK_ITEM_ID INT NOT NULL,
  MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID),
  CONSTRAINT fk_TEST_WORK_ITEMS_TESTS1
    FOREIGN KEY (TEST_ID)
    REFERENCES TESTS (ID)
    ON DELETE CASCADE
    ON UPDATE NO ACTION,
  CONSTRAINT fk_TEST_WORK_ITEMS_WORK_ITEMS1
    FOREIGN KEY (WORK_ITEM_ID)
    REFERENCES WORK_ITEMS (ID)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
CREATE INDEX fk_TEST_WORK_ITEMS_TESTS1_idx ON  TEST_WORK_ITEMS (TEST_ID);
CREATE INDEX fk_TEST_WORK_ITEMS_WORK_ITEMS1_idx ON  TEST_WORK_ITEMS (WORK_ITEM_ID);
CREATE TRIGGER update_timestamp_test_work_items BEFORE INSERT OR UPDATE ON TEST_WORK_ITEMS FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


DROP TABLE IF EXISTS TEST_METRICS;
CREATE TABLE IF NOT EXISTS TEST_METRICS (
  ID SERIAL,
  OPERATION VARCHAR(127) NOT NULL,
  ELAPSED BIGINT NOT NULL,
  TEST_ID INT NOT NULL,
  MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID),
  CONSTRAINT fk_TEST_METRICS_TESTS1
    FOREIGN KEY (TEST_ID)
    REFERENCES TESTS (ID)
    ON DELETE CASCADE
    ON UPDATE NO ACTION);
CREATE INDEX fk_TEST_METRICS_TESTS1_idx ON  TEST_METRICS (TEST_ID);
CREATE INDEX TEST_OPERATION ON  TEST_METRICS (OPERATION);
CREATE TRIGGER update_timestamp_test_metrics BEFORE INSERT OR UPDATE ON TEST_METRICS FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


DROP TABLE IF EXISTS SETTINGS;
CREATE TABLE IF NOT EXISTS SETTINGS (
  ID SERIAL,
  NAME VARCHAR(255) NOT NULL,
  VALUE VARCHAR(255) NULL,
  MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID));
CREATE UNIQUE INDEX SETTING_UNIQUE ON SETTINGS (NAME);
CREATE TRIGGER update_timestamp_settings BEFORE INSERT OR UPDATE ON SETTINGS FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


DROP TABLE IF EXISTS DEVICES;
CREATE TABLE IF NOT EXISTS DEVICES (
  ID SERIAL,
  MODEL VARCHAR(255) NOT NULL,
  SERIAL VARCHAR(255) NOT NULL,
  ENABLED BOOLEAN NOT NULL DEFAULT FALSE,
  LAST_STATUS BOOLEAN NOT NULL DEFAULT FALSE,
  DISCONNECTS INT NOT NULL DEFAULT 0,
  MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID));
CREATE UNIQUE INDEX SERIAL_UNIQUE ON DEVICES (SERIAL);
CREATE TRIGGER update_timestamp_devices BEFORE INSERT OR UPDATE ON DEVICES FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


DROP TABLE IF EXISTS WIDGETS;
CREATE TABLE IF NOT EXISTS WIDGETS (
  ID SERIAL,
  TITLE VARCHAR(255) NOT NULL,
  TYPE VARCHAR(20) NOT NULL DEFAULT 'linechart',
  SQL TEXT NOT NULL,
  MODEL TEXT NOT NULL,
  MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID));
CREATE TRIGGER update_timestamp_widgets BEFORE INSERT OR UPDATE ON WIDGETS FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


DROP TABLE IF EXISTS DASHBOARDS;
CREATE TABLE IF NOT EXISTS DASHBOARDS (
  ID SERIAL,
  TITLE VARCHAR(255) NOT NULL,
  TYPE VARCHAR(255) NOT NULL DEFAULT 'GENERAL',
  POSITION INT NOT NULL DEFAULT 0,
  MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID));
CREATE INDEX TITLE_UNIQUE ON DASHBOARDS (TITLE);
CREATE TRIGGER update_timestamp_dashboards BEFORE INSERT OR UPDATE ON DASHBOARDS FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


DROP TABLE IF EXISTS DASHBOARDS_WIDGETS;
CREATE TABLE IF NOT EXISTS DASHBOARDS_WIDGETS (
  ID SERIAL,
  DASHBOARD_ID INT NOT NULL,
  WIDGET_ID INT NOT NULL,
  POSITION INT NOT NULL DEFAULT 0,
  SIZE INT NOT NULL DEFAULT 1,
  MODIFIED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CREATED_AT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID),
  CONSTRAINT fk_DASHBOARDS_WIDGETS_DASHBOARDS1
    FOREIGN KEY (DASHBOARD_ID)
    REFERENCES DASHBOARDS (ID)
    ON DELETE CASCADE
    ON UPDATE NO ACTION,
  CONSTRAINT fk_DASHBOARDS_WIDGETS_WIDGETS1
    FOREIGN KEY (WIDGET_ID)
    REFERENCES WIDGETS (ID)
    ON DELETE CASCADE
    ON UPDATE NO ACTION);
CREATE INDEX fk_DASHBOARDS_WIDGETS_DASHBOARDS1_idx ON DASHBOARDS_WIDGETS (DASHBOARD_ID);
CREATE INDEX fk_DASHBOARDS_WIDGETS_WIDGETS1_idx ON DASHBOARDS_WIDGETS (WIDGET_ID);
CREATE UNIQUE INDEX DASHBOARD_WIDGET_UNIQUE ON DASHBOARDS_WIDGETS (DASHBOARD_ID, WIDGET_ID);
CREATE TRIGGER update_timestamp_dashboards_widgets BEFORE INSERT OR UPDATE ON DASHBOARDS_WIDGETS FOR EACH ROW EXECUTE PROCEDURE update_timestamp();
