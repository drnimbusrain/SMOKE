
        MODULE MODMVSMRG

!***********************************************************************
!  Module body starts at line
!
!  DESCRIPTION:
!     This module contains the public variables and allocatable arrays 
!     used by Movesmrg.
!
!  PRECONDITIONS REQUIRED:
!
!  SUBROUTINES AND FUNCTIONS CALLED:
!
!  REVISION HISTORY:
!     Created 4/10 by C. Seppanen
!
!***************************************************************************
!
! Project Title: Sparse Matrix Operator Kernel Emissions (SMOKE) Modeling
!                System
! File: @(#)$Id$
!
! COPYRIGHT (C) 2004, Environmental Modeling for Policy Development
! All Rights Reserved
! 
! Carolina Environmental Program
! University of North Carolina at Chapel Hill
! 137 E. Franklin St., CB# 6116
! Chapel Hill, NC 27599-6116
! 
! smoke@unc.edu
!
! Pathname: $Source$
! Last updated: $Date$ 
!
!****************************************************************************

        IMPLICIT NONE

        INCLUDE 'EMPRVT3.EXT'

C.........  Program settings
        LOGICAL, PUBLIC :: RPDFLAG  ! mode is rate-per-distance
        LOGICAL, PUBLIC :: RPVFLAG  ! mode is rate-per-vehicle
        LOGICAL, PUBLIC :: RPPFLAG  ! mode is rate-per-profile
        LOGICAL, PUBLIC :: MOPTIMIZE ! memory optimize option
        
        CHARACTER(300), PUBLIC :: MVFILDIR  ! directory for MOVES output files

C.........  Meteorology information
        CHARACTER(IOVLEN3), PUBLIC :: TVARNAME  ! name of temperature variable to read
        CHARACTER(IOVLEN3), PUBLIC :: DATANAME  ! name of activity data name from Temporal
        CHARACTER(16), PUBLIC :: METNAME        ! logical name for meteorology file

C.........  Average min and max temperatures
        REAL, ALLOCATABLE, PUBLIC :: AVGMIN( :,:,: )  ! minimum monthly temperature for each county
        REAL, ALLOCATABLE, PUBLIC :: AVGMAX( :,:,: )  ! maximum monthly temperature for each county

C.........  Text file unit numbers        
        INTEGER, PUBLIC :: XDEV         ! unit no. for county cross-reference file
        INTEGER, PUBLIC :: MDEV         ! unit no. for county fuel month file
        INTEGER, PUBLIC :: FDEV         ! unit no. for reference county file listing
        INTEGER, PUBLIC :: MMDEV        ! unit no. for Met4moves output file

C.........  Source to grid cell lookups
        INTEGER, ALLOCATABLE, PUBLIC :: NSRCCELLS( : )      ! no. cells for each source
        INTEGER, ALLOCATABLE, PUBLIC :: SRCCELLS( :,: )     ! list of cells for each source
        REAL,    ALLOCATABLE, PUBLIC :: SRCCELLFRACS( :,: ) ! grid cell fractions for each source

C.........  Reference county information
        INTEGER, ALLOCATABLE, PUBLIC :: NREFSRCS( : )       ! no. sources for each ref county
        INTEGER, ALLOCATABLE, PUBLIC :: REFSRCS( :,: )      ! list of srcs for each ref county
        CHARACTER(100), ALLOCATABLE, PUBLIC :: MRCLIST( :,: ) ! emfac file for each ref county and month

C.........  NONHAPTOG calculation information
        INTEGER, PUBLIC :: NHAP                                ! number of HAPs to subtract
        CHARACTER(IOVLEN3), ALLOCATABLE, PUBLIC :: HAPNAM( : ) ! list of HAPs

C.........  Emission factors data
        REAL,                 PUBLIC :: TEMPBIN           ! temperature buffer for max/min profiles

        INTEGER, ALLOCATABLE, PUBLIC :: EMPROCIDX( : )    ! index of emission process name
        INTEGER, ALLOCATABLE, PUBLIC :: EMPOLIDX( : )     ! index of emission pollutant name

        INTEGER, PUBLIC :: NEMTEMPS                       ! no. temperatures for current emision factors
        REAL, ALLOCATABLE, PUBLIC :: EMTEMPS( : )         ! list of temps for emission factors
        REAL, ALLOCATABLE, PUBLIC :: EMXTEMPS( : )        ! list of max. temps in profiles
        INTEGER, ALLOCATABLE, PUBLIC :: EMTEMPIDX( : )    ! index to sorted temperature profiles

        REAL, ALLOCATABLE, PUBLIC :: RPDEMFACS( :,:,:,:,: )  ! rate-per-distance emission factors
                                                             ! SCC, speed bin, temp, process, pollutant

        REAL, ALLOCATABLE, PUBLIC :: RPVEMFACS( :,:,:,:,:,: )  ! rate-per-vehicle emission factors
                                                               ! day, SCC, hour, temp, process, pollutant

        REAL, ALLOCATABLE, PUBLIC :: RPPEMFACS( :,:,:,:,:,: )  ! rate-per-profile emission factors
                                                               ! day, SCC, hour, temp profile, process, pollutant

C.........  Hourly speed data and control factor data
        LOGICAL, PUBLIC :: SPDFLAG                     ! use hourly speed data
        REAL, ALLOCATABLE, PUBLIC :: SPDPRO( :,:,:,: ) ! indexes: FIP, SCC, weekend/weekday, local hour
        LOGICAL, PUBLIC :: CFFLAG                     ! use control factor data
        REAL, ALLOCATABLE, PUBLIC :: CFPRO( :,:,:,: ) ! factor indexes: FIP, SCC, pollutant,month
        REAL, ALLOCATABLE, PUBLIC :: CFITC( :,:,:,: ) ! intercept indexes: FIP, SCC, pollutant,month

C.........  Index from per-source inventory array to INVSCC array (based on MICNY in MODSTCY)
        INTEGER, ALLOCATABLE, PUBLIC :: MISCC( : )     ! dim NMSRC

C.........  Speciation matrixes (mole- and mass-based)
        CHARACTER(16), PUBLIC :: MSNAME_L
        CHARACTER(16), PUBLIC :: PSNAME_L
        CHARACTER(16), PUBLIC :: MSNAME_S
        CHARACTER(16), PUBLIC :: PSNAME_S
        CHARACTER(16), PUBLIC :: GRDENV
        CHARACTER(16), PUBLIC :: TOTENV
        INTEGER, PUBLIC :: MNSMATV_L = 0  ! number of pol-to-species combinations
        INTEGER, PUBLIC :: PNSMATV_L = 0  ! number of pol-to-species combinations
        INTEGER, PUBLIC :: MNSMATV_S = 0
        INTEGER, PUBLIC :: PNSMATV_S = 0
        CHARACTER(PLSLEN3), ALLOCATABLE, PUBLIC :: MSVDESC_L( : )  ! pollutant-to-species names
        CHARACTER(PLSLEN3), ALLOCATABLE, PUBLIC :: PSVDESC_L( : )  ! pollutant-to-species names
        CHARACTER(PLSLEN3), ALLOCATABLE, PUBLIC :: MSVDESC_S( : )
        CHARACTER(PLSLEN3), ALLOCATABLE, PUBLIC :: PSVDESC_S( : )
        CHARACTER(PLSLEN3), ALLOCATABLE, PUBLIC :: MSVUNIT_L( : )  ! pollutant-to-species units
        CHARACTER(PLSLEN3), ALLOCATABLE, PUBLIC :: PSVUNIT_L( : )  ! pollutant-to-species units
        CHARACTER(PLSLEN3), ALLOCATABLE, PUBLIC :: MSVUNIT_S( : )
        CHARACTER(PLSLEN3), ALLOCATABLE, PUBLIC :: PSVUNIT_S( : )
        REAL, ALLOCATABLE, PUBLIC :: MSMATX_L( :,: )  ! speciation matrix, dim nmsrc
        REAL, ALLOCATABLE, PUBLIC :: PSMATX_L( :,: )  ! speciation matrix, dim nmsrc
        REAL, ALLOCATABLE, PUBLIC :: MSMATX_S( :,: )
        REAL, ALLOCATABLE, PUBLIC :: PSMATX_S( :,: )
        CHARACTER(IOULEN3), ALLOCATABLE, PUBLIC :: SPCUNIT_L( : ) ! speciation units
        CHARACTER(IOULEN3), ALLOCATABLE, PUBLIC :: SPCUNIT_S( : )

C.........  Non-speciated emissions reporting
        LOGICAL, ALLOCATABLE, PUBLIC :: EANAMREP( : )  ! indicates when non-speciation emissions should be saved

        END MODULE MODMVSMRG
