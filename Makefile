INCDIR   = include
SRCDIR   = src
OBJDIR   = obj
BINDIR   = bin
LIBDIR   = lib
EXEFILE  = decoder
EXE      = $(BINDIR)/$(EXEFILE)


#Source Files to looks for
SOURCES := $(wildcard $(SRCDIRS:%=src/%/*.cpp)) $(wildcard src/*.cpp)



INCLUDES  = -Iinclude
LINKDIR   = -L$(LIBDIR)
OGLIB     = 
GENLIBS   =

CXX       = g++
CXXLIBS   =
LDLIBS    = $(LINKDIR) $(WXLIBS) $(DYNLIB) $(OGLIB) $(GENLIBS)


CXXFLAGS  = -Wall $(INCLUDES) --std=c++17 -I$(EVIO)/Linux-x86_64/include  $(CXXLIBS) $$(root-config --cflags)
LDFLAGS   = -std=c++17 $(LDLIBS) $$(root-config --libs) -L$(EVIO)/Linux-x86_64/lib -levio



FLAG    = -DDEBUG
OBJECTS =  $(filter-out $(DOBJDIR)/Test.o, $(addprefix $(OBJDIR)/,$(SOURCES:$(SRCDIR)/%.cpp=%.o)))




## Default build target Debug
all: $(EXE)


$(EXE) : $(OBJECTS) | $(BINDIR)
	$(CXX) -o $@ $^ $(LDFLAGS)

$(OBJDIR)/%.o: $(SRCDIR)/%.cpp | $(OBJDIR)
	$(CXX) -o $@ -c $< $(FLAG) $(CXXFLAGS)




$(OBJDIR):
	mkdir $(OBJDIR)

$(BINDIR) :
	mkdir $(BINDIR)




clean:
	rm -rf obj/
	rm -rf $(OBJECTS) $(EXE)

# Include auto-generated dependencies rules
-include $(DOBJECTS:.o=.d)
