import time
import gitlab
import argparse
import jenkins

TARGET_BRANCHS_CAN_TRIGGER_PIPELINE = ['bd_1.12.13_dynamic_pre_test_ci']

JENKINS_URL = 'http://toutiao-ci.byted.org'
JENKINS_JOB = 'update_flutter_dynamicart_version'
POLLING_INTERVAL = 30
POLLING_TIMEOUT = 3000
GITLAB_URL = 'https://code.byted.org/'
GITLAB_PROJECT_ID = 20716

def canSkip(branch,commit_id):
    f = open('/home/linxuebin.01/.gitlab.config', 'r')
    gitlab_token = None
    for line in f.readlines():
        gitlab_token = line.strip()
    gl = gitlab.Gitlab(GITLAB_URL, private_token=gitlab_token)
    project = gl.projects.get(GITLAB_PROJECT_ID)
    commit = project.commits.get(commit_id)
    if commit.author_name == 'gongrui' and commit.title == 'CI Auto build app.dill':
        return True
    return False

def call_gen_dynamicart_app_dill_jenkins(branch,commit_id):
    f = open('/home/linxuebin.01/.jenkins.config', 'r')
    jenkins_username = None
    jenkins_password = None
    for line in f.readlines():
        line = line.strip()
        split_res = line.split("#")
        if len(split_res) == 2:
            jenkins_username = split_res[0]
            jenkins_password = split_res[1]

    server = jenkins.Jenkins(JENKINS_URL, username=jenkins_username,
                             password=jenkins_password)

    job_info = server.get_job_info(JENKINS_JOB)
    build_number = job_info['nextBuildNumber']
    print('build_number: {}'.format(build_number))
    server.build_job(JENKINS_JOB, {"BRANCH": branch,"COMMIT_ID": commit_id})
    end = time.time() + POLLING_TIMEOUT
    while True:
        time.sleep(POLLING_INTERVAL)
        build_info = server.get_build_info(JENKINS_JOB, build_number)
        if not build_info['building']:
            break
        if time.time() >= end:
            print('Error: Timeout')
            exit(1)

    console_log = server.get_build_console_output(JENKINS_JOB, build_number)
    print(console_log)

    print('jenkins result: ' + build_info['result'])
    if build_info['result'] == 'SUCCESS':
        exit(0)
    else:
        exit(1)    

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-b', '--branch',
                        required=True, help='Branch name')
    parser.add_argument('-c', '--commit_id',
                        required=True, help='Commit id')
    args = parser.parse_args()
    branch_name = args.branch
    commit_id = args.commit_id
    print('branch_name: {}'.format(branch_name))
    print('mr_id: {}'.format(commit_id))
    if branch_name is not None:
        if not canSkip(branch_name,commit_id):
            call_gen_dynamicart_app_dill_jenkins(branch_name,commit_id)
    else:
        print('Error: missing branch')
        exit(1)




