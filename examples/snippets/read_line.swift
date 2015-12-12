
// Found this one on the Swift Users mailing list. I didn't know that Swift had
// this built-in readLine method. Very cool.

func askName() {
	print("What's your name? ")
	let name = readLine()!
	print("Hello, \(name)... good to see you!")
}

askName()
