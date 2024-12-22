public class CSX_CMP_GenericErrorResponseWrapper {

    
    public String traceId { get; set; }
    public ErrorDetail error { get; set; }
    public List<Detail> details { get; set; }

    public class ErrorDetail {
        public Integer code { get; set; }
        public String message { get; set; }
        public String target { get; set; }
    }

    public class Detail {
        public Integer code { get; set; }
        public String message { get; set; }
        public String target { get; set; }
    }

    
    
    
}