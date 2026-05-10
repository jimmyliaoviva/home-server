# Plan: Deploy Homer from Gitea Registry to Maple

## Overview
Use Gitea Actions workflow to deploy custom Homer image from Gitea Container Registry to maple server.

## Target Details

| Property | Value |
|----------|-------|
| Server | maple (192.168.68.128) |
| SSH User | one |
| Repo Path | `/home/one/home-server` |
| Image | `gitea.jimmylab.duckdns.org/jimmy/homer:latest` |

---

## Implementation Steps

### Step 1: Create Branch
```bash
git checkout -b deploy_gitea_to_maple
```

### Step 2: Modify docker-compose.yml
File: `app/homer/docker-compose.yml`

Change image source:
```yaml
# From
image: b4bz/homer:latest
# To
image: gitea.jimmylab.duckdns.org/jimmy/homer:latest
```

### Step 3: Modify Ansible Playbook
File: `infra/ansible/deploy-docker-compose.yml`

Add docker login task before pulling image:

```yaml
- name: Login to Gitea Container Registry
  command: docker login gitea.jimmylab.duckdns.org -u {{ gitea_registry_user }} -p {{ gitea_registry_password }}
  args:
    chdir: "{{ repo_path }}/{{ app_path }}"
  when: gitea_registry_user is defined and gitea_registry_password is defined
  register: docker_login_result
  failed_when: false
```

Add `when` condition to `docker compose pull` task to check if login is required.

### Step 4: Add Secrets to Gitea
Add secrets in Gitea repository settings:
- `GITEA_REGISTRY_USER`: jimmy
- `GITEA_REGISTRY_PASSWORD`: [Gitea token with read:packages scope]

### Step 5: Update Deploy Workflow
File: `.gitea/workflows/deploy_image.yaml`

Modify Ansible command to include new extra-vars:
```yaml
ansible-playbook -i simple_inventory.py deploy-docker-compose.yml \
  --extra-vars "app_name=${{ env.deploy_image }} app_path=$APP_PATH deploy_action=up \
    gitea_registry_user=${{ secrets.GITEA_REGISTRY_USER }} \
    gitea_registry_password=${{ secrets.GITEA_REGISTRY_PASSWORD }}" \
  --limit ${{ env.target_server }} \
  -v
```

### Step 6: Commit and Push
```bash
git add app/homer/docker-compose.yml
git add infra/ansible/deploy-docker-compose.yml
git add .gitea/workflows/deploy_image.yaml
git commit -m "deploy: use Gitea registry image for homer on maple"
git push -u origin deploy_gitea_to_maple
```

### Step 7: Execute Gitea Actions
1. Go to Gitea Actions
2. Run `Deploy Docker Image` workflow
3. Select:
   - deploy_image: `homer`
   - target_server: `maple`

---

## Files to Modify

| File | Change |
|------|--------|
| `app/homer/docker-compose.yml` | Change image URL |
| `infra/ansible/deploy-docker-compose.yml` | Add docker login task |
| `.gitea/workflows/deploy_image.yaml` | Pass registry credentials |

## Required Gitea Secrets

| Secret | Description |
|--------|-------------|
| `GITEA_REGISTRY_USER` | Gitea username (jimmy) |
| `GITEA_REGISTRY_PASSWORD` | Gitea token with `read:packages` scope |

---

## Notes
- Gitea Container Registry: `gitea.jimmylab.duckdns.org/jimmy/homer:latest`
- Gitea token requires `read:packages` scope to pull images
- Docker login on target server will persist credentials for subsequent pulls from the same registry