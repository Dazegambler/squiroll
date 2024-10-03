print("test!!!!!!!!!!!\n");
function displayAllElements(obj,indent) {
	indent += " ";
    fprint("output.txt",indent+"----"+obj+"----\n");

    foreach (key, value in obj) {
        fprint("output.txt",indent+key + " : " + typeof(value) + "\n");

        if (typeof(value) == "table" || typeof(value) == "class") {
            displayAllElements(key,indent);
        }
    }
	fprint("output.txt",indent+"---------------\n")
}