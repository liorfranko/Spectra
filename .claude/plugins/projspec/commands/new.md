---
description: Create a new projspec specification with isolated git worktree
arguments:
  - name: spec_name
    description: Name for the new spec (kebab-case required, e.g., user-auth)
    required: true
---

# /projspec.new Command

This command creates a new projspec specification with:
- A unique 8-character hex ID
- An isolated git worktree for development
- Initial state.yaml configuration
- A brief.md placeholder for feature description

## Execution Steps

Follow these steps exactly to create a new spec:

### Step 1: Validate Input

Ensure the spec name is provided. If not, inform the user:
```
Usage: /projspec.new <spec-name>
Example: /projspec.new user-auth
```

### Step 2: Validate Spec Name Format

Validate that the spec name follows kebab-case convention and is suitable for git branch names.

**Validation Rules (must pass ALL):**

1. **Pattern Match**: Must match regex `^[a-z][a-z0-9]*(-[a-z0-9]+)*$`
   - Must start with a lowercase letter
   - Can contain only lowercase letters, numbers, and hyphens
   - No spaces, underscores, or special characters
   - No consecutive hyphens (`--`)
   - Cannot end with a hyphen

2. **Length Constraints**:
   - Minimum length: 2 characters
   - Maximum length: 50 characters

3. **Reserved Names**: The following names are reserved and cannot be used:
   - `main`
   - `master`
   - `head`
   - `develop`
   - `dev`
   - `release`
   - `staging`
   - `production`
   - `prod`
   - `test`
   - `spec`
   - `feature`
   - `hotfix`
   - `bugfix`

**Validation Logic (perform in order):**

```
1. Check if name is empty -> error
2. Check if length < 2 -> error: too short
3. Check if length > 50 -> error: too long
4. Check if name matches reserved list (case-insensitive) -> error: reserved name
5. Check if starts with lowercase letter -> error: must start with letter
6. Check if contains invalid characters -> error: invalid characters
7. Check if has consecutive hyphens -> error: no double hyphens
8. Check if ends with hyphen -> error: cannot end with hyphen
```

**If validation fails, show the appropriate error and stop:**

For **invalid format**:
```
Error: Invalid spec name '{SPEC_NAME}'.

Spec names must:
  - Start with a lowercase letter
  - Contain only lowercase letters (a-z), numbers (0-9), and hyphens (-)
  - Not contain consecutive hyphens (--)
  - Not end with a hyphen
  - Be between 2 and 50 characters

Valid examples:   user-auth, payment-v2, api-refactor, my-feature-1
Invalid examples: User-Auth, user_auth, 1-feature, my--feature, feature-
```

For **reserved name**:
```
Error: '{SPEC_NAME}' is a reserved name and cannot be used as a spec name.

Reserved names: main, master, head, develop, dev, release, staging,
                production, prod, test, spec, feature, hotfix, bugfix

Please choose a more descriptive name for your spec.
Examples: user-authentication, payment-gateway, api-v2-refactor
```

For **too short**:
```
Error: Spec name '{SPEC_NAME}' is too short (minimum 2 characters).

Please provide a descriptive name for your spec.
Examples: user-auth, payment-v2, api-refactor
```

For **too long**:
```
Error: Spec name '{SPEC_NAME}' is too long (maximum 50 characters).

Current length: {LENGTH} characters
Please shorten the spec name to 50 characters or less.
```

If valid, proceed to the next step.

### Step 3: Generate Spec ID

Generate an 8-character hex ID:

```bash
python -c "import uuid; print(uuid.uuid4().hex[:8])"
```

Store this as `SPEC_ID`.

### Step 4: Prepare Variables

Calculate the following values:
- `SPEC_NAME`: The provided spec name (use as-is, should be kebab-case)
- `SPEC_ID`: The 8-character hex from Step 3
- `BRANCH_NAME`: `spec/{SPEC_ID}-{SPEC_NAME}`
- `WORKTREE_PATH`: `worktrees/spec-{SPEC_ID}-{SPEC_NAME}`
- `SPEC_DIR`: `.projspec/specs/active/{SPEC_ID}`
- `TIMESTAMP`: Current UTC timestamp in ISO 8601 format

### Step 5: Validate Branch Doesn't Exist

Before creating the branch, verify it doesn't already exist:

```bash
git show-ref --verify --quiet refs/heads/{BRANCH_NAME}
```

If the command exits with status 0 (branch exists), output this error and stop:

```
Error: Branch '{BRANCH_NAME}' already exists. Use a different spec name or delete the existing branch.
```

If the command exits with non-zero status, the branch doesn't exist and you can proceed.

### Step 6: Validate Worktree Directory Doesn't Exist

Before creating the worktree, verify the directory doesn't already exist:

```bash
test -d {WORKTREE_PATH}
```

If the command exits with status 0 (directory exists), output this error and stop:

```
Error: Worktree directory '{WORKTREE_PATH}' already exists. Remove it first or use a different spec name.
```

If the command exits with non-zero status, the directory doesn't exist and you can proceed.

### Step 7: Create Git Branch

Create a new branch from the current HEAD:

```bash
git branch {BRANCH_NAME}
```

### Step 8: Create Git Worktree

Create an isolated worktree for this spec:

```bash
git worktree add {WORKTREE_PATH} {BRANCH_NAME}
```

### Step 9: Create Spec Directory

Create the spec's state directory in the main repository:

```bash
mkdir -p {SPEC_DIR}
```

### Step 10: Create state.yaml

Create the initial state file at `{SPEC_DIR}/state.yaml` with this content:

```yaml
# Projspec State File
# Auto-generated by /projspec.new

spec_id: {SPEC_ID}
name: {SPEC_NAME}
phase: new
created_at: {TIMESTAMP}
branch: {BRANCH_NAME}
worktree_path: {WORKTREE_PATH}
tasks: []
```

### Step 11: Create brief.md in Worktree

Create a placeholder brief file at `{WORKTREE_PATH}/specs/{SPEC_ID}/brief.md`:

First create the directory:
```bash
mkdir -p {WORKTREE_PATH}/specs/{SPEC_ID}
```

Then create brief.md with this content:

```markdown
# {SPEC_NAME}

## Overview

Describe the feature or change you want to implement.

## Requirements

- [ ] Requirement 1
- [ ] Requirement 2

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Notes

Any additional context or constraints.
```

### Step 12: Output Success Message

Report success to the user with next steps:

```
Spec created successfully!

  Spec ID:     {SPEC_ID}
  Name:        {SPEC_NAME}
  Branch:      {BRANCH_NAME}
  Worktree:    {WORKTREE_PATH}
  State file:  {SPEC_DIR}/state.yaml

Next steps:
  1. Navigate to the worktree: cd {WORKTREE_PATH}
  2. Edit the brief: specs/{SPEC_ID}/brief.md
  3. When ready, run: /projspec.plan
```

## Error Handling

If any step fails:
- For git branch errors: Check if the branch already exists
- For worktree errors: Verify the path doesn't already exist
- For file creation errors: Check directory permissions

Report the specific error and suggest remediation steps.

## Example Usage

```
User: /projspec.new user-auth

Claude creates:
- Branch: spec/a1b2c3d4-user-auth
- Worktree: worktrees/spec-a1b2c3d4-user-auth
- State: .projspec/specs/active/a1b2c3d4/state.yaml
- Brief: worktrees/spec-a1b2c3d4-user-auth/specs/a1b2c3d4/brief.md
```

## Valid and Invalid Name Examples

### Valid Spec Names
| Name | Why Valid |
|------|-----------|
| `user-auth` | Kebab-case, descriptive |
| `payment-v2` | Includes version number |
| `api-refactor` | Clear purpose |
| `my-feature-1` | Multiple segments with number |
| `ab` | Minimum length (2 chars) |
| `oauth2-integration` | Technical term with number |
| `fix-login-bug` | Action-oriented |

### Invalid Spec Names
| Name | Why Invalid |
|------|-------------|
| `main` | Reserved name |
| `master` | Reserved name |
| `HEAD` | Reserved name (case-insensitive) |
| `User-Auth` | Contains uppercase letters |
| `user_auth` | Contains underscore |
| `1-feature` | Starts with number |
| `my--feature` | Contains consecutive hyphens |
| `feature-` | Ends with hyphen |
| `-feature` | Starts with hyphen |
| `a` | Too short (min 2 chars) |
| `my feature` | Contains space |
| `feat@ure` | Contains special character |
