text = `hg summary`
$version = "1.0.0-#{text.match("parent:\s+(.+):")[1]}"
