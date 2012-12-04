#!/bin/sh
#
# Usage: sh htmlqqz.sh file
#
# Extracts and converts quick quizzes in a proto-HTML document file.htmlx.
# Commands, all of which must be on a line by themselves:
#
#	"<p>@@QQ@@": Start of a quick quiz.
#	"<p>@@QQA@@": Start of a quick-quiz answer.
#	"<p>@@QQE@@": End of a quick-quiz answer, and thus of the quick quiz.
#	"<p>@@QQAL@@": Place to put quick-quiz answer list.
#
# Places the result in file.html.

fn=$1
if test ! -r $fn.htmlx
then
	echo "Error: $fn.htmlx unreadable."
	exit 1
fi

echo "<!-- DO NOT HAND EDIT. -->" > $fn.html
echo "<!-- Instead, edit $fn.htmlx and run 'sh htmlqqz.sh $fn' -->" >> $fn.html
awk < $fn.htmlx >> $fn.html '

state == "" && $1 != "<p>@@QQ@@" && $1 != "<p>@@QQAL@@" {
	print $0;
	if ($0 ~ /^<p>@@QQ/)
		print "Bad Quick Quiz command: " NR " (expected <p>@@QQ@@ or <p>@@QQAL@@)." > "/dev/stderr"
	next;
}

state == "" && $1 == "<p>@@QQ@@" {
	qqn++;
	qqlineno = NR;
	haveqq = 1;
	state = "qq";
	print "<p><a name=\"Quick Quiz " qqn "\"><b>Quick Quiz " qqn "</b>:</a>"
	next;
}

state == "qq" && $1 != "<p>@@QQA@@" {
	qq[qqn] = qq[qqn] $0 "\n";
	print $0
	if ($0 ~ /^<p>@@QQ/)
		print "Bad Quick Quiz command: " NR ". (expected <p>@@QQA@@)" > "/dev/stderr"
	next;
}

state == "qq" && $1 == "<p>@@QQA@@" {
	state = "qqa";
	print "<br><a href=\"#qq" qqn "answer\">Answer</a>"
	next;
}

state == "qqa" && $1 != "<p>@@QQE@@" {
	qqa[qqn] = qqa[qqn] $0 "\n";
	if ($0 ~ /^<p>@@QQ/)
		print "Bad Quick Quiz command: " NR " (expected <p>@@QQE@@)." > "/dev/stderr"
	next;
}

state == "qqa" && $1 == "<p>@@QQE@@" {
	state = "";
	next;
}

state == "" && $1 == "<p>@@QQAL@@" {
	haveqq = "";
	print "<h2><a name=\"Answers to Quick Quizzes\">"
	print "Answers to Quick Quizzes</a></h2>"
	print "";
	for (i = 1; i <= qqn; i++) {
		print "<a name=\"qq" i "answer\"></a>"
		print "<p><b>Quick Quiz " i "</b>:"
		print qq[i];
		print "";
		print "</p><p><b>Answer</b>:"
		print qqa[i];
		print "";
		print "</p><p><a href=\"#Quick%20Quiz%20" i "\"><b>Back to Quick Quiz " i "</b>.</a>"
		print "";
	}
	next;
}

END {
	if (state != "")
		print "Unterminated Quick Quiz: " qqlineno "." > "/dev/stderr"
	else if (haveqq)
		print "Missing \"<p>@@QQAL@@\", no Quick Quiz." > "/dev/stderr"
}'
