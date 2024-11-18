#!/usr/bin/env rexx
/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright (c) 2007-2018 Rexx Language Association. All rights reserved.    */
/*                                                                            */
/* This program and the accompanying materials are made available under       */
/* the terms of the Common Public License v1.0 which accompanies this         */
/* distribution. A copy is also available at the following address:           */
/* http://www.oorexx.org/license.html                                         */
/*                                                                            */
/* Redistribution and use in source and binary forms, with or                 */
/* without modification, are permitted provided that the following            */
/* conditions are met:                                                        */
/*                                                                            */
/* Redistributions of source code must retain the above copyright             */
/* notice, this list of conditions and the following disclaimer.              */
/* Redistributions in binary form must reproduce the above copyright          */
/* notice, this list of conditions and the following disclaimer in            */
/* the documentation and/or other materials provided with the distribution.   */
/*                                                                            */
/* Neither the name of Rexx Language Association nor the names                */
/* of its contributors may be used to endorse or promote products             */
/* derived from this software without specific prior written permission.      */
/*                                                                            */
/* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS        */
/* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT          */
/* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS          */
/* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   */
/* OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,      */
/* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED   */
/* TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,        */
/* OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY     */
/* OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING    */
/* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS         */
/* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.               */
/*                                                                            */
/*----------------------------------------------------------------------------*/

/** testOORexx.rex
 * This is a simple kicker program.  It sets the framework directories into the
 * path and then invokes the program that does the actual work.
 */
arguments = arg(1)

   parse source . . file

   curDir  = directory()
   curPath = value("PATH", , 'ENVIRONMENT')
   testDir = file~left(file~caseLessPos("testOORexx.rex") - 2 )

   if testDir~pos("\") <> 0 then do
     sl = "\"
     pathSep = ";"
   end
   else do
     sl = "/"
     pathSep = ":"
   end

   ooRexxUnitDir = testDir || sl || "framework"
   newPath = curPath

   if \ isInPath(curPath, curDir, sl, pathSep) then
     newPath = curDir || pathSep || newPath

   if \ isInPath(curPath, ooRexxUnitDir, sl, pathSep) then
     newPath = ooRexxUnitDir || pathSep || newPath

   if \ isInPath(curPath, testDir, sl, pathSep) then
     newPath = testDir || pathSep || newPath

   -- Before changing the current working directory, be sure and save it in case
   -- it is needed.
   .local~ooTest.originalWorkingDir = curDir

   j = directory(testDir)
   j = value("PATH", newPath, 'ENVIRONMENT')

   retCode = 'worker.rex'(arguments)

   return retCode

/** isInPath() is a public routine from ooRexxUnit.  But, we don't have access
 * to ooRexxUnit.cls at this point.
 */
::routine isInPath
  use arg path, dir, sl, sep

  if .ooRexxUnit.OSName == "WINDOWS" then do
    if path~caseLessPos(dir || sep) <> 0 then return .true
    if path~caseLessPos(dir || sl || pathSep) <> 0 then return .true
    if path~right(dir~length)~caselessCompare(dir) == 0 then return .true
  end
  else do
    if path~pos(dir || sep) <> 0 then return .true
    if path~pos(dir || sl || pathSep) <> 0 then return .true
    if path~right(dir~length)~compare(dir) == 0 then return .true
  end
  return .false
