# legion-eval

GitHub Actions composite action that runs `legion eval run` as a CI quality gate.

## Usage

```yaml
- name: Run LLM Evaluation
  uses: LegionIO/.github/actions/legion-eval@main
  with:
    evaluator: toxicity
    dataset: test-cases
    threshold: '0.9'
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `evaluator` | yes | | Evaluator name or template |
| `dataset` | yes | | Dataset name or path to dataset file |
| `threshold` | no | `0.8` | Minimum pass rate (0.0–1.0) |
| `ruby-version` | no | `3.4` | Ruby version |
| `model` | no | | LLM model for eval (uses legion-llm default if unset) |
| `config-dir` | no | | Path to Legion config directory |

## Outputs

| Output | Description |
|--------|-------------|
| `pass-rate` | Achieved pass rate (0.0–1.0) |
| `result` | `pass` or `fail` |

## Examples

### Basic gate

```yaml
jobs:
  eval:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: LegionIO/.github/actions/legion-eval@main
        with:
          evaluator: toxicity
          dataset: test-cases
          threshold: '0.9'
```

### Capture outputs

```yaml
jobs:
  eval:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run eval
        id: eval
        uses: LegionIO/.github/actions/legion-eval@main
        with:
          evaluator: coherence
          dataset: ./eval/dataset.json
          threshold: '0.85'
          model: claude-3-5-haiku-20241022
      - name: Report
        run: echo "Pass rate ${{ steps.eval.outputs.pass-rate }} — ${{ steps.eval.outputs.result }}"
```

### Use the reusable workflow instead

For common CI patterns (PR comments, automatic fail), use the reusable workflow:

```yaml
jobs:
  eval-gate:
    uses: LegionIO/.github/.github/workflows/eval-gate.yml@main
    with:
      evaluator: toxicity
      dataset: test-cases
      threshold: '0.9'
```

## Requirements

- The `legionio`, `lex-eval`, and `lex-dataset` gems are installed automatically.
- LLM provider credentials must be available as environment variables or via Legion config.
