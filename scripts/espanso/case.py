#!/usr/bin/env python3
import sys
import re


def tokenize(text):
    # Split camelCase and PascalCase boundaries
    text = re.sub(r"([a-z])([A-Z])", r"\1 \2", text)
    # Split on spaces, underscores, hyphens, dots
    tokens = re.split(r"[\s_\-\.]+", text)
    return [t.lower() for t in tokens if t]


def transform(tokens, fmt):
    match fmt:
        case "snake_case":
            return "_".join(tokens)
        case "SCREAMING_SNAKE":
            return "_".join(t.upper() for t in tokens)
        case "camelCase":
            return tokens[0] + "".join(t.capitalize() for t in tokens[1:])
        case "PascalCase":
            return "".join(t.capitalize() for t in tokens)
        case "kebab-case":
            return "-".join(tokens)
        case "dot.case":
            return ".".join(tokens)
        case "Title Case":
            return " ".join(t.capitalize() for t in tokens)
        case "lowercase":
            return " ".join(tokens)
        case "UPPERCASE":
            return " ".join(t.upper() for t in tokens)
        case _:
            return " ".join(tokens)


FORMATS = [
    "snake_case",
    "SCREAMING_SNAKE",
    "camelCase",
    "PascalCase",
    "kebab-case",
    "dot.case",
    "Title Case",
    "lowercase",
    "UPPERCASE",
]

if __name__ == "__main__":
    args = sys.argv[1:]

    if "--list" in args:
        text = args[args.index("--list") + 1]
        tokens = tokenize(text)
        for fmt in FORMATS:
            print(f"{fmt}: {transform(tokens, fmt)}")

    elif "--format" in args:
        fmt = args[args.index("--format") + 1]
        text = args[args.index("--format") + 2]
        tokens = tokenize(text)
        print(transform(tokens, fmt))
