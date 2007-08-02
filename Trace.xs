#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int (*old_runops) ( pTHX );
OP * old_op;
int currently_being_traced = 0;
SV * cached_tracer_rv = (SV*)NULL;
SV * ptr;

static void
set_tracer( pTHX_ SV *tracer_rv ) {
    /* Validate tracer_rv */
    if ( ! SvROK( tracer_rv ) ) {
        croak( aTHX_ "tracer_rv is a reference" );
    }
    if ( ! SVt_PVCV == SvTYPE( SvRV( tracer_rv ) ) ) {
        croak( aTHX_ "tracer_rv is a code reference" );
    }

    /* Initialize/set the tracing function */
    if ( cached_tracer_rv == (SV*)NULL ) {
        cached_tracer_rv = newSVsv( tracer_rv );
    }
    else {
        SvSetSV( cached_tracer_rv, tracer_rv );
    }
}

int runops_trace(pTHX) {
  dSP;
  SV* op_obj;

  while (PL_op) {
    old_op    = PL_op;

    if ( 1 == currently_being_traced ) {
      /* make the environment as normal as possible for callbacks */
      PL_runops = old_runops;
      currently_being_traced = 0;

      /* Hey ho, do that tracing callback */
      sv_setuv( ptr, PTR2UV( old_op ) );
      SPAGAIN;
      PUSHMARK(SP);
      XPUSHs( ptr );
      PUTBACK;
      
      call_sv( cached_tracer_rv, G_VOID | G_DISCARD );
      SPAGAIN;

      /* set up debugging again */
      PL_runops = runops_trace;
      currently_being_traced = 1;
    }

    PL_op     = CALL_FPTR( old_op->op_ppaddr )( aTHX );
    PERL_ASYNC_CHECK();
  }    

  TAINT_NOT;
  return 0;
}

MODULE = Runops::Trace PACKAGE = Runops::Trace

PROTOTYPES: ENABLE

void
_trace_function( tracer_rv, to_trace_rv)
    SV * tracer_rv
    SV * to_trace_rv
  PROTOTYPE: $$
  CODE:
    set_tracer( aTHX_ tracer_rv );

    /* Call the function to trace */
    currently_being_traced = 1;
    call_sv( to_trace_rv, G_VOID | G_DISCARD | G_EVAL | G_KEEPERR );
    currently_being_traced = 0;

void
enable_global_tracing(tracer_rv)
    SV * tracer_rv
  PROTOTYPE: $
  CODE:
    set_tracer( aTHX_ tracer_rv );
    currently_being_traced = 1;

void
disable_global_tracing()
  PROTOTYPE:
  CODE:
    currently_being_traced = 0;

BOOT:
  old_runops = PL_runops;
  PL_runops  = runops_trace;
  ptr = newSVuv( 0 );
