
        SUBROUTINE RDLINES( FDEV, DESCRIPT, NLINES, LINES )

C**************************************************************************
C  subroutine body starts at line
C
C  DESCRIPTION:
C      This subroutine reads the lines of an ASCII file to an array of strings
C
C  PRECONDITIONS REQUIRED:
C
C  SUBROUTINES AND FUNCTIONS CALLED:
C
C  REVISION  HISTORY:
C
C**************************************************************************
C
C Project Title: Sparse Matrix Operator Kernel Emissions (SMOKE) Modeling
C                System
C File: @(#)$Id$
C
C COPYRIGHT (C) 2000, MCNC--North Carolina Supercomputing Center
C All Rights Reserved
C
C See file COPYRIGHT for conditions of use.
C
C Environmental Programs Group
C MCNC--North Carolina Supercomputing Center
C P.O. Box 12889
C Research Triangle Park, NC  27709-2889
C
C env_progs@mcnc.org
C
C Pathname: $Source$
C Last updated: $Date$ 
C
C***************************************************************************

        IMPLICIT NONE

C...........   INCLUDES

        INCLUDE 'EMCNST3.EXT'   !  emissions constant parameters

C...........   EXTERNAL FUNCTIONS and their descriptions:
        CHARACTER*2   CRLF
        EXTERNAL      CRLF

C...........   SUBROUTINE ARGUMENTS
        INTEGER       FDEV            !  file unit number
        CHARACTER*(*) DESCRIPT        !  file description
        INTEGER       NLINES          !  number of lines in file
        CHARACTER*(*) LINES( NLINES ) !  ASCII lines in file

C...........   Other local variables
        INTEGER         IOS     !  i/o status
        INTEGER         IREC    !  line counter
        INTEGER         L, LSAV, L2   !  length indices
        INTEGER         N       !  record counter

        CHARACTER*300   LINE    !  line buffer
        CHARACTER*300   MESG    !  message buffer

        CHARACTER*16 :: PROGNAME = 'RDLINES' ! program name

C***********************************************************************
C   begin body of subroutine RDLINES

        L = LEN( LINES( 1 ) )     

        IREC = 0
        LSAV = 0
        N    = 0
11      CONTINUE

            READ( FDEV, 93000, END=22, IOSTAT=IOS ) LINE
            IREC = IREC + 1
 
            L2 = LEN_TRIM( LINE )

            IF( IOS .GT. 0 ) THEN
                WRITE( MESG, 94010 ) 
     &                 'Error', IOS,  'reading ' // 
     &                 DESCRIPT( 1:LEN_TRIM( DESCRIPT ) ) //
     &                 ' file at line', IREC
                CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )

C............. Keep track of width that is larger than that allocated
            ELSE IF( L2 .GT. L ) THEN
                IF( L2 .GT. LSAV ) LSAV = L2
                GO TO 11

C............. Skip blank lines
            ELSE IF( L2 .EQ. 0 ) THEN   
                GO TO 11

            END IF

            N = N + 1
            IF( N .LE. NLINES ) THEN
                LINES( N ) = LINE
            END IF

        GO TO  11

22      CONTINUE        !  exit from loop reading FDEV

        IF( N .GT. NLINES ) THEN
            WRITE( MESG,94010 ) 'WARNING: ' // 
     &             DESCRIPT( 1:LEN_TRIM( DESCRIPT ) ) //
     &             CRLF() // BLANK10 // 'file only read for first ',
     &             NLINES, ' lines of ', N, ' total lines.'
            CALL M3MSG2( MESG ) 
        END IF

        IF( LSAV .GT. 0 ) THEN
            WRITE( MESG,94010 ) 'ERROR: ' // 
     &             DESCRIPT( 1:LEN_TRIM( DESCRIPT ) ) //
     &             CRLF() // BLANK10 // 'file line width is ',
     &             LSAV, ' but allocated string length is ', L
            CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 ) 
        END IF

C.........  Rewind file
        REWIND( FDEV )

        RETURN

C******************  FORMAT  STATEMENTS   ******************************

C...........   Formatted file I/O formats............ 93xxx

93000   FORMAT( A )

C...........   Internal buffering formats............ 94xxx

94010   FORMAT( 10( A, :, I8, :, 1X ) )

        END
