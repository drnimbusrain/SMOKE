
        SUBROUTINE RDGREF( FDEV )

C***********************************************************************
C  subroutine body starts at line 
C
C  DESCRIPTION:
C     Reads the gridding cross-reference file for area or mobile sources.  It
C     allocates memory (locally) for reading the unsorted x-refs. It sorts the
C     x-refs for processing. It allocates memory for the appropriate x-ref 
C     tables and populates the tables (passed via modules).
C
C  PRECONDITIONS REQUIRED:
C     File unit FDEV already is opened... MORE
C
C  SUBROUTINES AND FUNCTIONS CALLED:
C
C  REVISION  HISTORY:
C     Created 4/99 by M. Houyoux
C
C****************************************************************************/
C
C Project Title: Sparse Matrix Operator Kernel Emissions (SMOKE) Modeling
C                System
C File: @(#)$Id$
C
C COPYRIGHT (C) 1998, MCNC--North Carolina Supercomputing Center
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

C.........  MODULES for public variables
C.........  This module is for cross reference tables
        USE MODXREF

C.........  This module contains the lists of unique source characteristics
        USE MODLISTS

C.........  This module contains the information about the source category
        USE MODINFO

        IMPLICIT NONE

C...........   INCLUDES

        INCLUDE 'EMCNST3.EXT'   !  emissions constant parameters

C...........   EXTERNAL FUNCTIONS and their descriptions:
        LOGICAL         CHKINT
        CHARACTER*2     CRLF
        INTEGER         FIND1
        INTEGER         FINDC
        INTEGER         GETFLINE
        INTEGER         INDEX1
        INTEGER         STR2INT

        EXTERNAL  CHKINT, CRLF, FIND1, FINDC, GETFLINE, INDEX1, STR2INT

C...........   SUBROUTINE ARGUMENTS
        INTEGER, INTENT (IN) :: FDEV   ! cross-reference file unit no.
 
C...........   Local parameters
        INTEGER    , PARAMETER :: AREATYP  = 1
        INTEGER    , PARAMETER :: BIOGTYP  = 2
        INTEGER    , PARAMETER :: MOBILTYP = 3

        CHARACTER*6, PARAMETER :: LOCCATS( 3 ) = 
     &                         ( / 'AREA  ', 'BIOG  ', 'MOBILE' / )

C...........   Array of input fields
        CHARACTER(LEN=SCCLEN3)  FIELDARR( 3 )
  
C...........   Other local variables
        INTEGER         I, J, J1, J2, K, L, N    !  counters and indices

        INTEGER         FIP     !  temporary FIPS code
        INTEGER         IDUM    !  dummy variable
        INTEGER         IOS     !  i/o status
        INTEGER         IREC    !  record counter
        INTEGER         ISRG    !  tmp surrogate ID
        INTEGER         JS      !  position of SCC in source chars in x-ref file
        INTEGER         LINTYPE !  temporary source category code
        INTEGER         LPCK    !  length of point definition packet
        INTEGER      :: NCP = 0 !  input point source header parm
        INTEGER         NLINES  !  number of lines
        INTEGER         NXREF   !  number of valid x-ref entries
        INTEGER         RDT     !  temporary road class code
        INTEGER         THISTYP !  index in LOCCATS for CATEGORY
        INTEGER         VTYPE   !  temporary vehicle type number

        LOGICAL      :: EFLAG = .FALSE.   !  true: error found
        LOGICAL      :: LDUM  = .FALSE.   !  dummy
        LOGICAL      :: SKIPREC = .FALSE. !  true: record skipped in x-ref file

        CHARACTER*2            SCC2     !  1st & 2nd character of SCC
        CHARACTER*300          LINE     !  line buffer
        CHARACTER*300          MESG     !  message buffer
        CHARACTER(LEN=ALLLEN3) CSRCALL  !  buffer for source char, incl pol
        CHARACTER(LEN=FIPLEN3) CFIP     !  buffer for CFIPS code
        CHARACTER(LEN=SICLEN3) CDUM     !  dummy buffer for SIC code
        CHARACTER(LEN=SCCLEN3) CHKZERO  !  buffer to check for zero SCC
        CHARACTER(LEN=SCCLEN3) SCCZERO  !  zero SCC
        CHARACTER(LEN=SCCLEN3) TSCC     !  temporary SCC or roadway type
        CHARACTER(LEN=SCCLEN3) FIELD2   !  tmp 2nd field for sorting x-ref
        CHARACTER(LEN=SCCLEN3) FIELD4   !  tmp 4th field for sorting x-ref

        CHARACTER*16 :: PROGNAME = 'RDGREF' ! program name

C***********************************************************************
C   begin body of subroutine RDGREF

C.........  Ensure that the CATEGORY is valid
C.........  Use THISTYP to  et LINTYPE when aren't sure if the record is for
C           current source category or not.
        THISTYP = INDEX1( CATEGORY, 3, LOCCATS )

        IF( THISTYP .LE. 0 ) THEN
            L = LEN_TRIM( CATEGORY )
            MESG = 'INTERNAL ERROR: category "' // CATEGORY( 1:L ) // 
     &             '" is not valid in routine ' // PROGNAME
            CALL M3MSG2( MESG ) 
            CALL M3EXIT( PROGNAME, 0, 0, ' ', 2 ) 

        ENDIF

C.........  Create the zero SCC
        SCCZERO = REPEAT( '0', SCCLEN3 )

C.........  Get the number of lines in the file
        NLINES = GETFLINE( FDEV, 'Gridding cross reference file' )

C.........  Allocate memory for unsorted data used in all source categories 
        ALLOCATE( ISRGCDA( NLINES ), STAT=IOS )
        CALL CHECKMEM( IOS, 'ISRGCDA', PROGNAME ) 
        ALLOCATE( CSCCTA( NLINES ), STAT=IOS )
        CALL CHECKMEM( IOS, 'CSCCTA', PROGNAME )
        ALLOCATE( CSRCTA( NLINES ), STAT=IOS )
        CALL CHECKMEM( IOS, 'CSRCTA', PROGNAME )
        ALLOCATE( INDXTA( NLINES ), STAT=IOS )
        CALL CHECKMEM( IOS, 'INDXTA', PROGNAME )

C.........  Set up constants for loop.

C.........  Second pass through file: read lines and store unsorted data for
C           the source category of interest
        IREC   = 0
        N      = 0
        CDUM = ' ' 
        FIELD2 = ' ' 
        FIELD4 = ' ' 
        DO I = 1, NLINES

            READ( FDEV, 93000, END=999, IOSTAT=IOS ) LINE
            IREC = IREC + 1

            IF ( IOS .NE. 0 ) THEN
                EFLAG = .TRUE.
                WRITE( MESG,94010 ) 
     &              'I/O error', IOS, 
     &              'reading GRIDDING X-REF file at line', IREC
                CALL M3MESG( MESG )
                CYCLE
            END IF

C.............  Skip blank lines
            IF( LINE .EQ. ' ' ) CYCLE

C.............  Depending on source category, transfer line to temporary
C               fields.  In cases where blanks are allowed, do not use
C               STR2INT to prevent warning messages.
            SELECT CASE( CATEGORY )

            CASE( 'AREA' )    ! Same fields for area and mobile
                CALL PARSLINE( LINE, 3, FIELDARR )

                CFIP = FIELDARR( 1 )
                TSCC = FIELDARR( 2 )

C.................  Post-process x-ref information to scan for '-9', pad
C                   with zeros, compare SCC version master list.
                CALL FLTRXREF( CFIP, CDUM, TSCC, ' ', IDUM, 
     &                         IDUM, IDUM, LDUM, SKIPREC   )

                FIELD2 = TSCC

            CASE( 'BIOG' )
c note: insert here when needed

            CASE( 'MOBILE' )

                CALL PARSLINE( LINE, 3, FIELDARR )

                L = LEN_TRIM( FIELDARR( 2 ) )

C.................  Make sure roadway type is an integer
                IF( .NOT. CHKINT( FIELDARR( 2 ) ) ) THEN
                    EFLAG = .TRUE.
                    WRITE( MESG,94010 ) 'ERROR: Roadway type ' //
     &                     'is not an integer at line', IREC
                    CALL M3MESG( MESG )

C.................  Make sure roadway type is two digits
                ELSE IF( L .GT. 2 ) THEN
                    EFLAG = .TRUE.
                    WRITE( MESG,94010 ) 'ERROR: Roadway type ' //
     &                     'is more than two digits at line', IREC
                    CALL M3MESG( MESG )

                END IF

                CFIP = FIELDARR( 1 )
                TSCC = FIELDARR( 2 )   ! actually roadway type

C.................  Post-process x-ref information to scan for '-9', pad
C                   with zeros.  Do not include SCC in call below
C                   because this input file does not use SCC.
                CALL FLTRXREF( CFIP, CDUM, SCCZERO, ' ', IDUM, 
     &                         IDUM, IDUM, LDUM, SKIPREC   )

                CALL PADZERO( TSCC )

                FIELD4 = TSCC

            END SELECT

C.............  Make sure that the spatial surrogates code is an integer
            IF( .NOT. CHKINT( FIELDARR( 3 ) ) ) THEN
                EFLAG = .TRUE.
                WRITE( MESG,94010 ) 'ERROR: Spatial surrogates ' //
     &                 'code is not an integer at line', IREC
                CALL M3MESG( MESG )
            END IF

C.............  If this record is in error, or should be skipped because 
C               it doesn't match any sources, go to next iteration
            IF( EFLAG .OR. SKIPREC ) CYCLE

C.............  Convert surrogate code to an integer
            ISRG = STR2INT( FIELDARR( 3 ) )

            N = N + 1
            IF( N .GT. NLINES ) CYCLE  ! Ensure no overflow

C.............  Store case-indpendent fields
            INDXTA ( N ) = N
            ISRGCDA( N ) = ISRG
            CSCCTA ( N ) = TSCC

C.............  Store sorting criteria as right-justified in fields
C.............  For mobile, we are using "TSCC" to store the roadway
C               type so that we can use the XREFTBL subroutine.  Put TSCC
C               in the spot for the link ID (field 4) so that records 
C               will be sorted properly.
            CSRCALL = ' '
            CALL BLDCSRC( CFIP, FIELD2, CHRBLNK3, FIELD4,
     &                    CHRBLNK3, CHRBLNK3, CHRBLNK3,
     &                    POLBLNK3, CSRCALL   )

            CSRCTA( N ) = CSRCALL( 1:SC_ENDP( NCHARS ) )

        END DO      ! End of loop on I for reading in speciation x-ref file

C.........  Reset number of cross-reference entries in case some were dropped
        NXREF = N

C.........  Write errors for problems with input
        IF( NXREF .EQ. 0 ) THEN
            EFLAG = .TRUE.
            MESG = 'ERROR: No valid gridding cross-reference entries!'
            CALL M3MSG2( MESG )

        ELSEIF( NXREF .GT. NLINES ) THEN
            EFLAG = .TRUE.
            WRITE( MESG,94010 ) 'INTERNAL ERROR: dimension for ' //
     &             'storing gridding cross-reference was', NLINES,
     &             CRLF() // BLANK10 // 'but actually needed', NXREF
            CALL M3MSG2( MESG )

        ENDIF

C.......  Check for errors reading XREF file, and abort
        IF( EFLAG ) THEN
            MESG = 'Problem reading gridding cross-reference file.'
            CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
        ENDIF

        CALL M3MSG2( 'Processing gridding cross-reference file...' )

        CALL SORTIC( NXREF, INDXTA, CSRCTA )

C.........  Group cross-reference data into tables for different groups
        CALL XREFTBL( 'GRIDDING', NXREF )

C.........  Deallocate other temporary unsorted arrays
        DEALLOCATE( ISRGCDA, CSRCTA, CSCCTA, INDXTA )

C.........  Rewind file
        REWIND( FDEV )

        RETURN

C.........  Error message for reaching the end of file too soon
999     MESG = 'End of file reached unexpectedly. ' //
     &         'Check format of gridding' // CRLF() // BLANK5 //
     &         'cross-reference file.'
        CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )

C******************  FORMAT  STATEMENTS   ******************************

C...........   Formatted file I/O formats............ 93xxx

93000   FORMAT( A )

C...........   Internal buffering formats............ 94xxx

94010   FORMAT( 10( A, :, I8, :, 1X ) )

        END SUBROUTINE RDGREF
