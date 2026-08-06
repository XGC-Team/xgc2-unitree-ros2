# XGC2 ROS 2 compatibility matrix

The XGC2 branch keeps every upstream ROS package name unchanged:

- `unitree_go`
- `unitree_api`
- `unitree_hg`
- `unitree_ros2_example`

XGC2 product, Debian, job, and artifact names may carry an XGC2 prefix. ROS
package names, message namespaces, and `package.xml` identities must not.

## Supported build tuples

The matrix is an explicit list rather than a Cartesian product because each ROS
distribution has a matching Ubuntu base distribution.

| ROS 2 | Ubuntu | Debian arch | GitHub runner | Official base image |
|---|---|---|---|---|
| Humble | Jammy 22.04 | amd64 | `ubuntu-22.04` | `ros:humble-ros-base-jammy` |
| Humble | Jammy 22.04 | arm64 | `ubuntu-22.04-arm` | `ros:humble-ros-base-jammy` |
| Jazzy | Noble 24.04 | amd64 | `ubuntu-24.04` | `ros:jazzy-ros-base-noble` |
| Jazzy | Noble 24.04 | arm64 | `ubuntu-24.04-arm` | `ros:jazzy-ros-base-noble` |

Both image tags are Docker Official Images with `linux/amd64` and
`linux/arm64/v8` manifests. Pull-request CI uses only GitHub-hosted ephemeral
runners, so public pull requests never execute on Thor.

Foxy/Focal is intentionally outside the required matrix. Foxy is end-of-life
and its tag is no longer in the current Docker Official Image support set. The
upstream Foxy workflow remains historical compatibility evidence, not an XGC2
release gate.

## Acceptance checks

Every tuple must:

1. assert the actual ROS distribution, Ubuntu codename, and Debian architecture;
2. build `unitree_go`, `unitree_api`, and `unitree_hg` without renaming them;
3. build and install `unitree_ros2_example`;
4. discover all four B2/B2W executables from the install space;
5. introspect representative message interfaces without starting any node.

The CI never runs `b2_sport_client`, `b2_stand_example`, or any other control
sample. Discovering an installed executable is not authorization to execute it.

## Thor boundary

Do not register a repository-level Thor self-hosted runner with this public
fork. A pull request can contain arbitrary workflow code, so labels, a manual
trigger, and an environment approval on one trusted workflow are not a
repository-wide runner access boundary.

The public fork proves native arm64 compatibility on GitHub-hosted ephemeral
runners. A later Thor validation must be initiated from a private trusted
orchestrator (or directly by an administrator), check out an immutable reviewed
commit, and keep the build host isolated from robot actuation networks. It may
compile and inspect packages only. Robot-side observation remains a separate,
explicitly approved, read-only test.
