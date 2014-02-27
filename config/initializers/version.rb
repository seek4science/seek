text = `hg summary`
$version = "0.9.0-#{text.match("parent:\s+(.+):")[1]}"
