module logger;

import std.conv : to;
import std.traits : isNumeric, isArray;
import std.stdio : writeln;

enum LogLevel {
	Debug = "debug",
	Info = "info",
	Warning = "warn",
	Error = "error"
}

enum NoLog;

private string makeHeader(LogLevel level, string file) {
	return '[' ~ level ~ "] " ~ file ~ ": ";
}

string log(Data : string)(Data str, LogLevel level, string file = __FILE__) {
	return makeHeader(level, file) ~ str;
}

string log(Data : bool)(Data boolean, LogLevel level, string file = __FILE__) {
	return makeHeader(level, file) ~ (boolean ? "T" : "F");
}

string log(Data)(Data value, LogLevel level, string file = __FILE__)
if (isNumeric!Data) {
	return makeHeader(level, file) ~ to!string(value);
}

string log(Data)(Data arr, LogLevel level, string file = __FILE__)
if (isArray!Data) {
	
	import std.array : Appender;

	// appender declaration
	Appender!(char[]) output;

	size_t len = arr.length;

	output.put(makeHeader(level, file));
	output.put('[');
	foreach(i, ref value; arr) {
		output.put(value.to!string);
		if (i != len - 1)
			output.put(", ");
	}
	output.put(']');

	// returns copy of the char array
	return output.data.idup();
}


string log(Data)(Data obj, LogLevel level, string file = __FILE__)
if (is(Data == struct) || is(Data == class)) {
	import std.array : Appender;  // appender for output
	import std.traits : hasUDA; // if object has user defined attributes
	import std.traits : isFunction; // detect if argument is a function

	Appender!(char[]) output;
	output.put(makeHeader(level, file));
	
	// check if object has method toString
	static if(__traits(hasMember, Data, "toString") && isFunction!(obj.toString)) {
		output.put(obj.toString());
		
		// generic toString for Data
	} else {
		output.put(__traits(identifier, Data));
		output.put('(');

		// iterate through all members of type Data at compile time
		static foreach(member; __traits(allMembers, Data))
		{{
			// gets that member;
			mixin("alias Member = __traits(getMember, Data, member);");

			/* check if member is not a function and if it
			   does not contain enum NoLog -> if it had NoLog
			   data it should not have been printed */

			if (!isFunction!(Member) && !hasUDA!(Member, NoLog)) {

				// insert obj.member at compile time => much faster
				auto memberValue = mixin("obj." ~ member);
				output.put(memberValue.to!string);
				output.put(", ");
			}
		}}
		output.put(')');
	}
	return output.data.idup();
}

// Unittests for basic types: strings, ints, bools
unittest
{
	assert("[info] logger.d: Oceiros" == "Oceiros".log(LogLevel.Info));
	assert("[debug] logger.d: 69" == 69.log(LogLevel.Debug));
	assert("[warn] logger.d: T" == true.log(LogLevel.Warning));
	assert("[error] logger.d: F" == false.log(LogLevel.Error));
}

// Unittest for array
unittest
{
	assert("[info] logger.d: [1337, 1000100]" == [1337, 1_000_100].log(LogLevel.Info));
}

unittest
{
	struct Stats {
		long souls;
		bool optional;

		string toString() const {
			return __traits(identifier, Stats) ~ "(" ~ souls.to!string ~ ", " ~ optional.to!string ~ ")";
		}
	}

	struct Boss {
		string name;
		int number;
		Stats stats;

		string toString() const {
			return __traits(identifier, Boss) ~ "(" ~ name ~ ", " ~ number.to!string ~ ", " ~ stats.to!string ~ ")";
		}
	}

	struct Dog {
		string name;
		int number;
		@NoLog Stats stats;
	}

   	Boss firstBoss = Boss("Iudex Gundyr", 1, Stats(3000, false));
	assert("[warn] logger.d: Boss(Iudex Gundyr, 1, Stats(3000, false))" ==
		   firstBoss.log(LogLevel.Warning));
	Dog rex = Dog("Rex", 1, Stats(6000, true));
	writeln(rex.log(LogLevel.Warning));
}
