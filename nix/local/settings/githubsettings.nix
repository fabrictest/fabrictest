# https://github.com/apps/settings
let
  inherit (inputs) std;
in
std.lib.dev.mkNixago {

  output = ".github/settings.yml";

  format = "yaml";

  hook.mode = "copy";

  data = {
    repository = {
      name = "fabrictest";
      description = "@tautologicc's homelab";
      homepage = "https://fabricte.st";
      topics = "lix";
      private = false;
      visibility = "public";
      has_issues = true;
      has_projects = false;
      has_wiki = false;
      is_template = false;
      default_branch = "main";
      allow_squash_merge = true;
      allow_merge_commit = false;
      allow_rebase_merge = false;
      allow_auto_merge = true;
      delete_branch_on_merge = true;
      allow_update_branch = true;
      use_squash_pr_title_as_default = true;
      squash_merge_commit_title = "PR_TITLE";
      squash_merge_commit_message = "PR_BODY";
      merge_commit_title = "PR_TITLE";
      merge_commit_message = "PR_BODY";
      enable_automated_security_fixes = false;
      enable_vulnerability_alerts = true;
    };

    collaborators = [
      {
        username = "tautologicc";
        permission = "admin";
      }
    ];

    rulesets = [
      {
        target = "branch";
        name = "Prevent tampering with default branch";
        enforcement = "active";
        conditions.ref_name = {
          include = [ "~DEFAULT_BRANCH" ];
          exclude = [ ];
        };
        rules = [
          { type = "deletion"; }
          { type = "non_fast_forward"; }
          { type = "required_linear_history"; }
          { type = "required_signatures"; }
        ];
      }
      {
        target = "branch";
        name = "Require PRs to the default branch to pass the quality bar";
        enforcement = "active";
        conditions.ref_name = {
          include = [ "~DEFAULT_BRANCH" ];
          exclude = [ ];
        };
        rules = [
          {
            type = "pull_request";
            parameters = {
              required_approving_review_count = 1;
              dismiss_stale_reviews_on_push = true;
              require_code_owner_review = true;
              require_last_push_approval = true;
              required_review_thread_resolution = true;
              automatic_copilot_code_review_enabled = true;
              allowed_merge_methods = [ "squash" ];
            };
          }
          /*
            {
              type = "required_status_checks";
              parameters = {
                strict_required_status_checks_policy = false;
                required_status_checks =
                  let
                    workflow = cell.lib.readYAML (self + /.github/workflows/build-lix.yaml);
                    job = [ workflow.jobs.test-examples.name ];
                    lix-version = l.pipe lix.packages [
                      (l.filterAttrs (name: _: name != "lix-stores"))
                      (l.mapAttrsToList (_: drv: drv.version))
                    ];
                    inherit (workflow.jobs.build-lix-stores.strategy.matrix) runs-on;
                    context = l.pipe { inherit job lix-version runs-on; } [
                      l.cartesianProduct
                      (l.map (c: "${c.job} (${c.lix-version}, ${c.runs-on})"))
                    ];
                    integration_id = [ 15368 ]; # GitHub Actions
                  in
                  l.cartesianProduct { inherit context integration_id; };
              };
            }
          */
        ];
        bypass_actors = [
          {
            actor_id = 5;
            actor_type = "RepositoryRole";
            bypass_mode = "always";
          }
        ];
      }
      {
        target = "tag";
        name = "Prevent deletion of release tags";
        enforcement = "active";
        conditions.ref_name = {
          include = [ "refs/tags/v*" ];
          exclude = [ ];
        };
        rules = [
          { type = "deletion"; }
        ];
      }
      {
        target = "tag";
        name = "Prevent tampering with release tags";
        enforcement = "active";
        conditions.ref_name = {
          include = [ "refs/tags/v*.*.*" ];
          exclude = [ ];
        };
        rules = [
          { type = "non_fast_forward"; }
          { type = "update"; }
        ];
      }
    ];

    # labels = [ ];

  };

}
