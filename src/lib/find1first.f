
        INTEGER FUNCTION FIND1FIRST( KEY, N, LIST )

C***********************************************************************
C  function body starts at line 55
C
C  DESCRIPTION:
C       Returns first instance of integer KEY in LIST
C
C  PRECONDITIONS REQUIRED:
C
C  SUBROUTINES AND FUNCTIONS CALLED: FIND1
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
        IMPLICIT NONE
        
C...........   EXTERNAL FUNCTIONS 
        INTEGER   FIND1
        
        EXTERNAL  FIND1   

C.........  Function arguments
        INTEGER, INTENT (IN) :: KEY        ! key to search for
        INTEGER, INTENT (IN) :: N          ! number of entries in LIST
        INTEGER, INTENT (IN) :: LIST( N )  ! table to be searched
        
C.........  Local function variables            
        INTEGER INDEX

C***********************************************************************
C   begin body of function FIND1FIRST

C.........  Use FIND1 to get location of key        
        INDEX = FIND1( KEY, N, LIST )
        
C.........  If the key is found, search backward until the first entry is reached            
        IF( INDEX > 0 ) THEN
            DO
                IF( INDEX < 1 .OR. LIST( INDEX ) /= KEY ) EXIT
                INDEX = INDEX - 1
            END DO
            	
            INDEX = INDEX + 1	
        END IF

        FIND1FIRST = INDEX
        
        RETURN 
    
        END FUNCTION FIND1FIRST

C..........................................................
        
        INTEGER FUNCTION FINDR1FIRST( KEY, N, LIST )

C***********************************************************************
C  function body starts at line 132
C
C  DESCRIPTION:
C       Returns first instance of real KEY in LIST
C
C  PRECONDITIONS REQUIRED:
C
C  SUBROUTINES AND FUNCTIONS CALLED: FIND1R
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
    
        IMPLICIT NONE
        
C...........   EXTERNAL FUNCTIONS 
        INTEGER   FINDR1
        
        EXTERNAL  FINDR1   

C.........  Function arguments
        REAL,    INTENT (IN) :: KEY        ! key to search for
        INTEGER, INTENT (IN) :: N          ! number of entries in LIST
        REAL,    INTENT (IN) :: LIST( N )  ! table to be searched
        
C.........  Local function variables            
        INTEGER INDEX

C***********************************************************************
C   begin body of function FINDR1FIRST

C.........  Use FINDR1 to get location of key        
        INDEX = FINDR1( KEY, N, LIST )
        
C.........  If the key is found, search backward until the first entry is reached            
        IF( INDEX > 0 ) THEN
            DO
                IF( INDEX < 1 .OR. LIST( INDEX ) /= KEY ) EXIT
                INDEX = INDEX - 1
            END DO
            	
            INDEX = INDEX + 1	
        END IF

        FINDR1FIRST = INDEX
        
        RETURN 
    
        END FUNCTION FINDR1FIRST