text = `hg summary`
$version = "1.1.0-#{text.match("parent:\s+(.+):")[1]}"
