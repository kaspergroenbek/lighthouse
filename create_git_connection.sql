CREATE OR REPLACE GIT REPOSITORY lighthouse_repo
  API_INTEGRATION = github_git_api
  GIT_CREDENTIALS = github_pat_secret
  ORIGIN = 'https://github.com/kaspergroenbek/lighthouse.git';
