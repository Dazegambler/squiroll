#pragma once

#ifndef CRASHHANDLER_H
#define CRASHHANDLER_H

#include <windows.h>
#include <signal.h>
#include <dbghelp.h>
#include <stdio.h>
#include "log.h"

void printStackTrace();
void signalHandler(int signum);

#endif