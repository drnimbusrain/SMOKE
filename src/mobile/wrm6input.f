
        SUBROUTINE WRM6INPUT( GRPLIST, NLINES, SDEV, MDEV, 
     &                        CTYLIST, TEMPS, NCOUNTY, VOLNAM, 
     &                        SCENNUM, SRCNUM, RPLCFLAG )

C***********************************************************************
C  subroutine body starts at line 121
C
C  DESCRIPTION:
C       Creates the concatenated MOBILE6 input file
C
C  PRECONDITIONS REQUIRED:
C
C  SUBROUTINES AND FUNCTIONS CALLED:  none
C
C  REVISION  HISTORY:
C     10/01: Created by C. Seppanen
C
C***********************************************************************
C
C Project Title: Sparse Matrix Operator Kernel Emissions (SMOKE) Modeling
C                System
C File: @(#)$Id$
C
C COPYRIGHT (C) 2002, MCNC Environmental Modeling Center
C All Rights Reserved
C
C See file COPYRIGHT for conditions of use.
C
C Environmental Modeling Center
C MCNC
C P.O. Box 12889
C Research Triangle Park, NC  27709-2889
C
C smoke@emc.mcnc.org
C
C Pathname: $Source$
C Last updated: $Date$ 
C
C***********************************************************************

C.........  MODULES for public variables
C.........  This module contains the inventory arrays
        USE MODSOURC

C.........  This module contains the information about the source category
        USE MODINFO
        
C...........   This module contains emission factor tables and related
        USE MODEMFAC

        IMPLICIT NONE

C...........   INCLUDES:

        INCLUDE 'EMCNST3.EXT'   !  emissions constant parameters
        INCLUDE 'M6CNST3.EXT'   !  MOBILE6 constants

C...........   EXTERNAL FUNCTIONS and their descriptions:
        INTEGER           GETFLINE
        INTEGER           ENVINT
        INTEGER           FIND1
        INTEGER           STR2INT
        CHARACTER(LEN=80) WRSPDVMT
        CHARACTER(LEN=2)  CRLF    
        
        EXTERNAL  GETFLINE, ENVINT, FIND1, STR2INT, WRSPDVMT, CRLF

C...........   SUBROUTINE ARGUMENTS
        INTEGER,      INTENT (IN)   :: GRPLIST( NLINES,3 )   ! GROUP file contents
        INTEGER,      INTENT (IN)   :: NLINES                ! no. lines in GROUP file
        INTEGER,      INTENT (IN)   :: SDEV                  ! SPDSUM file unit no.
        INTEGER,      INTENT (IN)   :: MDEV                  ! M6INPUT file unit no.
        INTEGER,      INTENT (IN)   :: CTYLIST( NCOUNTY )    ! counties in temperature file
        REAL,         INTENT (IN)   :: TEMPS( NCOUNTY, 24 )  ! temps per county
        INTEGER,      INTENT (IN)   :: NCOUNTY               ! no. counties in temps array
        CHARACTER(*), INTENT (IN)   :: VOLNAM                ! volatile pollutant name
        INTEGER,      INTENT(INOUT) :: SCENNUM               ! total number of scenarios
        INTEGER,      INTENT(INOUT) :: SRCNUM                ! total number of sources
        LOGICAL,      INTENT (IN)   :: RPLCFLAG              ! true: replace temps in scenario

C...........   Local allocatable arrays
        CHARACTER(LEN=150),     ALLOCATABLE :: M6SCEN( : )    ! M6 scenario file

C...........   Other local variables
        INTEGER I, J, K                   ! counters and indices                     
        
        INTEGER          IOS              ! I/O status
        INTEGER, SAVE :: JYEAR            ! emission factor year
        INTEGER          NLINESCEN        ! number of lines in M6 scenario file
        INTEGER, SAVE :: NLINESPD         ! number of lines in speed summary file
        INTEGER          FDEV             ! unit no. for M6 scenario file
        INTEGER          PREVCTY          ! previous county number in SPDSUM file
        INTEGER          CURRCTY          ! current county number in SPDSUM file
        INTEGER          CTYNUM           ! number of counties in SPDSUM file
        INTEGER          CTYPOS           ! position of county in temperature array
        INTEGER          CURRLINE         ! current line in SPDSUM
        INTEGER          CURRROAD         ! road type from SPDSUM file
        INTEGER          PREVROAD         ! previous road type
        INTEGER          STSCEN           ! starting line of scenario data in scenario file
        INTEGER          LASAFLAG         ! local-as-arterial setting
        
        REAL    CURRSPD                   ! speed value from SPDSUM file
        REAL    PREVSPD                   ! previous speed

        LOGICAL      :: EFLAG   = .FALSE. ! true: error found
        LOGICAL      :: NEWSCEN = .FALSE. ! true: print current and create a new scenario
        LOGICAL,SAVE :: INITIAL = .TRUE.  ! true: first time through subroutine
        
        CHARACTER(LEN=FIPLEN3) CURRCOUNTY            ! current county FIPS code
        CHARACTER(LEN=FIPLEN3) REFCOUNTY             ! ref. county FIPS code for curr. county
        CHARACTER(LEN=6)       SCENARIO              ! scenario number
        
        CHARACTER(LEN=60),SAVE :: SPDDIR   ! directory for creating speed vmt files
        CHARACTER(LEN=80)         SPDFILE  ! name of SPEED VMT file for M6 input file
        CHARACTER(LEN=300)        SCENFILE !  M6 scenario file name
        CHARACTER(LEN=300)        MESG     !  message buffer

        CHARACTER*16 :: PROGNAME = 'WRM6INPUT'   ! program name
        
C***********************************************************************
C   begin body of subroutine WRM6INPUT

        IF( INITIAL ) THEN
        	
C.............  Get speed vmt directory information from the environment
            MESG = 'Path where speed vmt files for ' //
     &             'MOBILE6 will be written'
            CALL ENVSTR( 'SMK_SPDPATH', MESG, '.', SPDDIR, IOS )
            
            IF( IOS /= 0 ) THEN
                MESG = 'WARNING: Speed vmt files being placed '//
     &                 'executable directory because ' // CRLF() //
     &                 BLANK10 // 'environment variable SMK_SPDPATH '//
     &                 'is not set properly'
                CALL M3MSG2( MESG )
            END IF
            
C.............  Get the year for computing the emission factors
            MESG = 'Emission factors year'
            JYEAR = ENVINT( 'EF_YEAR', MESG, 1988, IOS )
            
C.............  Write message about which year emission factors will be for
            WRITE( MESG,94010 ) 
     &             'NOTE: Emission factors are for year', JYEAR
            CALL M3MSG2( MESG )
     
C.............  Get number of lines in speed summary file
            NLINESPD = GETFLINE( SDEV, 'Speed summary file' )
        
            INITIAL = .FALSE.
        END IF

C.........  Reset SPDSUM file and line count        
        REWIND( SDEV )
        CURRLINE = 1

C.........  Write Mobile6 header info to input file
        CALL WRM6HEADER( MDEV )
        
C.........  Loop through counties in GROUP file
        DO I = 1, NLINES

C.............  Get info from GROUP file
            WRITE( CURRCOUNTY, '(I6)' ) GRPLIST( I,1 )
            CALL PADZERO( CURRCOUNTY )
            
            WRITE( REFCOUNTY, '(I6)' ) GRPLIST( I,2 )
            CALL PADZERO( REFCOUNTY )
            
            LASAFLAG = GRPLIST( I,3 )

C.............  Open M6 scenario file for current reference county
            CALL OPENSCEN( REFCOUNTY, FDEV, SCENFILE )

C.............  Get number of lines in M6 scenario file
            MESG = 'MOBILE6 scenario file for county' // REFCOUNTY
            NLINESCEN = GETFLINE( FDEV, MESG )

            IF( ALLOCATED( M6SCEN ) ) DEALLOCATE( M6SCEN )            
            ALLOCATE( M6SCEN( NLINESCEN + 1 ), STAT=IOS )
            CALL CHECKMEM( IOS, 'M6SCEN', PROGNAME )
            M6SCEN = ' '
            
C.............  Read M6 scenario file into array            
            CALL RDLINES( FDEV, MESG, NLINESCEN, M6SCEN )

C.............  Close scenario file
            CLOSE( FDEV )

C.............  Find beginning of scenario commands 
            STSCEN = 0

            DO J = 1, NLINESCEN
                IF( M6SCEN( J )(1:20) == 'SCENARIO RECORD    :' ) THEN
                    STSCEN = J
                    EXIT
                END IF
            END DO

            IF( STSCEN == 0 ) THEN
                EFLAG = .TRUE.
                WRITE( MESG, 93000 ) 'ERROR: Scenario file for county '
     &                 // REFCOUNTY // ' does not include the '
     &                 // 'SCENARIO RECORD command.'
                CALL M3MESG( MESG )
                CYCLE
            END IF           

C.............  Check M6 scenario for unused commands and calendar year
            CALL CHKM6SCN( SCENFILE, M6SCEN, NLINESCEN, JYEAR )

            IF( RPLCFLAG ) THEN
            	
C.................  Find current county in temperatures array
                CTYPOS = FIND1( STR2INT(CURRCOUNTY), NCOUNTY, CTYLIST )
                
                IF( CTYPOS <= 0 ) THEN
                    EFLAG = .TRUE.
                    MESG = 'ERROR: Could not find county ' // 
     &                     CURRCOUNTY // ' in hourly temperature file'
                    CALL M3MESG( MESG )
                    CYCLE
                END IF
             
C.................  Replace temperatures in M6 scenario
                CALL RPLCTEMP( CURRCOUNTY, TEMPS, NCOUNTY, 
     &                         M6SCEN, NLINESCEN, CTYPOS )
            END IF

C.............  Write run level commands to M6 input file
            DO J = 1, STSCEN - 1
                WRITE( MDEV, 93000 ) 
     &                      M6SCEN( J )( 1:LEN_TRIM( M6SCEN( J ) ) )
            END DO

C.............  Select M6 output based on volatile pollutant name            
            SELECT CASE( VOLNAM( 1:LEN_TRIM( VOLNAM ) ) )
            CASE ( 'THC' )
                WRITE( MDEV,93000 ) 'EXPRESS HC AS THC  :'
            CASE ( 'NMHC' )
                WRITE( MDEV,93000 ) 'EXPRESS HC AS NMHC :'
            CASE ( 'TOG' )
                WRITE( MDEV,93000 ) 'EXPRESS HC AS TOG  :'
            CASE ( 'NMOG' )
                WRITE( MDEV,93000 ) 'EXPRESS HC AS HMOG :'
            CASE ( 'VOC' )
                WRITE( MDEV,93000 ) 'EXPRESS HC AS VOC  :'
            CASE DEFAULT
                MESG = 'ERROR: Unrecognized hydrocarbon type'
                CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
            END SELECT

C.............  Move to starting line for current county in SPDSUM file
            CALL GETSPDLN( SDEV, CURRCOUNTY, NLINESPD, CURRLINE )

            IF( CURRLINE == 0 ) THEN
            	EFLAG = .TRUE.
            	
                WRITE( MESG, 93000 ) 'ERROR: Could not find county ' 
     &                 // CURRCOUNTY // ' in speed summary file.'
                CALL M3MESG( MESG )
                CYCLE
            END IF

            PREVROAD = M6LOCAL
            PREVSPD  = 0.0

C.............  Read speeds and sources
            DO
                CALL RDSPDLINE( SDEV, SCENNUM, CURRCOUNTY, NLINESPD,
     &                          LASAFLAG, CURRROAD, CURRSPD, CURRLINE,
     &                          SRCNUM )
                
                IF( CURRROAD == M6LOCAL ) THEN
                    CURRSPD = PREVSPD
                END IF
                 
                IF( CURRROAD == M6ARTERIAL ) THEN
                    NEWSCEN = .TRUE.
                END IF

                IF( PREVROAD == CURRROAD ) THEN
                    NEWSCEN = .TRUE.
                END IF

                IF( PREVROAD == M6FREEWAY .AND. 
     &              CURRROAD == M6LOCAL ) THEN
                    NEWSCEN = .TRUE.
                END IF

                IF( NEWSCEN ) THEN               	
                	
C.....................  Create speed vmt file
                    SPDFILE = WRSPDVMT( PREVSPD, CURRSPD, SPDDIR )
                    
                    IF( SPDFILE == '' ) THEN
                    	EFLAG = .TRUE.
                    	
                        WRITE( MESG,93000 ) 'ERROR: Could not create '
     &                         // 'speed vmt file: ' // CRLF() 
     &                         // BLANK5 // SPDFILE
                        CALL M3MESG( MESG )
                        CYCLE
                    END IF
                    
C.....................  Write M6 scenario to M6INPUT                   
                    WRITE( SCENARIO, '(I6)' ) SCENNUM
                    CALL PADZERO( SCENARIO )
                    WRITE( MDEV, 93000 ) 
     &                      'SCENARIO RECORD    : ' // SCENARIO
                    DO J = STSCEN, NLINESCEN + 1
                        IF( M6SCEN( J ) == ' ' ) CYCLE
                        WRITE( MDEV, 93000 ) 
     &                      M6SCEN( J )( 1:LEN_TRIM( M6SCEN( J ) ) )
                    END DO
                    WRITE( MDEV, 93000 )
     &                      'PARTICLE SIZE      : 2.5'
                    WRITE( MDEV, 93000 )
     &                      'SPEED VMT          : ' 
     &                      // SPDFILE( 1:LEN_TRIM( SPDFILE ) )
                    WRITE( MDEV, 93000 ) BLANK10
                    
C.....................  Increment scenario number
                    SCENNUM = SCENNUM + 1

                END IF

                NEWSCEN = .FALSE.

                IF( CURRROAD == M6LOCAL ) EXIT

                PREVROAD = CURRROAD
                PREVSPD  = CURRSPD

            END DO
        
C.............  Write end of run command to M6 input file
            WRITE( MDEV,93000 ) 'END OF RUN         :'
            WRITE( MDEV,93000 ) ' '

        END DO

C.........  Abort if error found while writing M6 input file
        IF( EFLAG ) THEN
            MESG = 'Problem writing MOBILE6 input file'
            CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
        END IF

        RETURN

C******************  FORMAT  STATEMENTS   ******************************

C...........   Formatted file I/O formats............ 93xxx

93000   FORMAT( A )
93010   FORMAT( I6, :, 1X, I1, 1X, F6.2, 7( 1X, I6 ), 1X, 1A )  

C...........   Internal buffering formats............ 94xxx

94010   FORMAT( 10( A, :, I8, :, 1X ) )
94020   FORMAT( 10( A, :, F6.2, :, 1X ) )

        END SUBROUTINE WRM6INPUT
        
