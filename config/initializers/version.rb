text = `hg log --limit 1`
$version = "Alpha #{text.match("changeset:\s+(.+):")[1]} - #{text.match("date:\s+(.+) \+")[1]}"
