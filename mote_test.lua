local mote = require("mote")

-- case 1: direct concat basics
local expected = [[123]]

assert(expected ==
	mote("examples/concat.mote", { one = 1, two = 2, three = 3 }))

-- case 2: display user listing
local expected = [[
<h1>Users</h1>
<ul>
		<li><a href="1">John</a></li>
		<li><a href="2">Jane</a></li>
	</ul>
]]
local users = {
	{ name = "John", id = 1 },
	{ name = "Jane", id = 2 }
}

assert(expected ==
	mote("examples/users.mote", { users = users, title = "Users" }))

-- case 3: number looping
local expected = [[
<ul>
	<li>1</li>
	<li>2</li>
	<li>3</li>
	<li>4</li>
	<li>5</li>
	<li>6</li>
	<li>7</li>
	<li>8</li>
	<li>9</li>
	<li>10</li>
</ul>
]]

assert(expected ==
	mote("examples/loop.mote", { N = 10 }))

print("All tests passed")
