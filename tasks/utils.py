from contextlib import contextmanager
import os
import subprocess

def _get_local_path(repo):
    return os.path.join(os.environ["DATADOG_ROOT"], repo)

def local_uncommited_changes_exist(repo):
    with dd_repo_temp_cwd(repo):
        return subprocess.check_output(["git", "status", "--porcelain"]) != b""

@contextmanager
def dd_repo_temp_cwd(repo=""):
    current_dir = os.getcwd()
    try:
        os.chdir(_get_local_path(repo))
        yield
    finally:
        os.chdir(current_dir)

def checkout_latest_main(repo):
    with dd_repo_temp_cwd(repo):
        subprocess.check_call(["git", "checkout", "main"])
        subprocess.check_call(["git", "pull"])

def create_branch_and_push_changes(
        repo,
        branch,
        commit_msg,
        commit_args= None,
        labels= None,
        ):
    subprocess.check_call(["git", "checkout", "-b", branch])
    subprocess.check_call(["git", "add", ".", ":!venv"])
    subprocess.check_call(["git", "commit", "-am", commit_msg])
    subprocess.check_call(["git", "push", "origin", branch])
